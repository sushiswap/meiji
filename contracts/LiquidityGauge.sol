// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVotingEscrow.sol";

function _min(uint256 a, uint256 b) pure returns (uint256) {
    if (a < b) return a;
    return b;
}

contract LiquidityGauge is Ownable, ReentrancyGuard, ILiquidityGauge {
    using SafeERC20 for IERC20;

    uint256 internal constant TOKENLESS_PRODUCTION = 40;
    uint256 internal constant BOOST_WARMUP = 2 * 7 * 86400;
    uint256 internal constant WEEK = 604800;

    address public immutable override minter;
    address public immutable override lpToken;
    address public immutable override controller;
    address public immutable override votingEscrow;

    mapping(address => uint256) public override balanceOf;
    uint256 public override totalSupply;
    uint256 public override futureEpochTime;

    mapping(address => uint256) public override workingBalances;
    uint256 public override workingSupply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    int128 public override period;
    mapping(int128 => uint256) public override periodTimestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    mapping(int128 => uint256) public override integrateInvSupply; // bump epoch when rate() changes

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public override integrateInvSupplyOf;
    mapping(address => uint256) public override integrateCheckpointOf;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units: rate * t = already number of coins per address to issue
    mapping(address => uint256) public override integrateFraction;

    uint256 public override inflationRate;

    bool public isKilled;

    constructor(address lpAddr, address _minter) {
        require(lpAddr != address(0), "LG: INVALID_LP_ADDR");
        require(_minter != address(0), "LG: INVALID_MINTER");

        lpToken = lpAddr;
        minter = _minter;
        address _controller = IMinter(_minter).controller();
        controller = _controller;
        votingEscrow = IGaugeController(_controller).votingEscrow();
        periodTimestamp[0] = block.timestamp;
        inflationRate = IMinter(_minter).rate();
        futureEpochTime = IMinter(_minter).futureEpochTimeWrite();
    }

    function integrateCheckpoint() external view override returns (uint256) {
        return periodTimestamp[period];
    }

    /**
     * @notice Record a checkpoint for `addr`
     * @param addr User address
     * @return bool success
     */
    function userCheckpoint(address addr) external override returns (bool) {
        require(msg.sender == addr || msg.sender == minter, "LG: FORBIDDEN");
        _checkpoint(addr);
        _updateLiquidityLimit(addr, balanceOf[addr], totalSupply);
        return true;
    }

    /**
     * @notice Get the number of claimable tokens per user
     * @dev This function should be manually changed to "view" in the ABI
     * @return uint256 number of claimable tokens per user
     */
    function claimableTokens(address addr) external override returns (uint256) {
        _checkpoint(addr);
        return integrateFraction[addr] - IMinter(minter).minted(addr, address(this));
    }

    /**
     * @notice Kick `addr` for abusing their boost
     * @dev Only if either they had another voting event, or their voting escrow lock expired
     * @param addr Address to kick
     */
    function kick(address addr) external override {
        address _votingEscrow = votingEscrow;
        uint256 tLast = integrateCheckpointOf[addr];
        (, , uint256 tVE, ) = IVotingEscrow(_votingEscrow).userPointHistory(
            addr,
            IVotingEscrow(_votingEscrow).userPointEpoch(addr)
        );
        uint256 _balance = balanceOf[addr];

        require(IERC20(_votingEscrow).balanceOf(addr) == 0 || tVE > tLast, "LG: KICK_NOT_ALLOWED");
        require(workingBalances[addr] > (_balance * TOKENLESS_PRODUCTION) / 100, "LG: KICK_NOT_NEEDED");

        _checkpoint(addr);
        _updateLiquidityLimit(addr, balanceOf[addr], totalSupply);
    }

    /**
     *    @notice Deposit `_value` LP tokens
     *    @param _value Number of tokens to deposit
     *    @param addr Address to deposit for
     */
    function deposit(uint256 _value, address addr) external override nonReentrant {
        _checkpoint(addr);

        if (_value != 0) {
            uint256 _balance = balanceOf[addr] + _value;
            uint256 _supply = totalSupply + _value;
            balanceOf[addr] = _balance;
            totalSupply = _supply;

            _updateLiquidityLimit(addr, _balance, _supply);

            IERC20(lpToken).safeTransferFrom(msg.sender, address(this), _value);
        }

        emit Deposit(addr, _value);
    }

    /**
     * @notice Withdraw `_value` LP tokens
     * @param _value Number of tokens to withdraw
     */
    function withdraw(uint256 _value) external override nonReentrant {
        _checkpoint(msg.sender);

        uint256 _balance = balanceOf[msg.sender] - _value;
        uint256 _supply = totalSupply - _value;
        balanceOf[msg.sender] = _balance;
        totalSupply = _supply;

        _updateLiquidityLimit(msg.sender, _balance, _supply);

        IERC20(lpToken).safeTransfer(msg.sender, _value);

        emit Withdraw(msg.sender, _value);
    }

    /**
     * @notice Toggle the killed status of the gauge
     */
    function killMe() external override onlyOwner {
        isKilled = !isKilled;
    }

    /**
     * @notice Calculate limits which depend on the amount of CRV token per-user.
     *         Effectively it calculates working balances to apply amplification
     *         of CRV production by CRV
     * @param addr User address
     * @param l User's amount of liquidity (LP tokens)
     * @param L Total amount of liquidity (LP tokens)
     */
    function _updateLiquidityLimit(
        address addr,
        uint256 l,
        uint256 L
    ) internal {
        // To be called after totalSupply is updated
        address _votingEscrow = votingEscrow;
        uint256 votingBalance = IERC20(_votingEscrow).balanceOf(addr);
        uint256 votingTotal = IERC20(_votingEscrow).totalSupply();

        uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;
        if ((votingTotal > 0) && (block.timestamp > periodTimestamp[0] + BOOST_WARMUP))
            lim += (((L * votingBalance) / votingTotal) * (100 - TOKENLESS_PRODUCTION)) / 100;

        lim = _min(l, lim);
        uint256 oldBal = workingBalances[addr];
        workingBalances[addr] = lim;
        uint256 _workingSupply = workingSupply + lim - oldBal;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _workingSupply);
    }

    /**
     * @notice Checkpoint for a user
     * @param addr User address
     */
    function _checkpoint(address addr) internal {
        address _minter = minter;
        address _controller = controller;
        int128 _period = period;
        uint256 _periodTime = periodTimestamp[_period];
        uint256 _integrateInvSupply = integrateInvSupply[_period];
        uint256 rate = inflationRate;
        uint256 newRate = rate;
        uint256 prevFutureEpoch = futureEpochTime;
        if (prevFutureEpoch >= _periodTime) {
            futureEpochTime = IMinter(_minter).futureEpochTimeWrite();
            newRate = IMinter(_minter).rate();
            inflationRate = newRate;
        }
        IGaugeController(_controller).checkpointGauge(address(this));

        uint256 _workingBalance = workingBalances[addr];
        uint256 _workingSupply = workingSupply;

        if (isKilled) rate = 0;
        // Stop distributing inflation as soon as killed

        // Update integral of 1/total
        if (block.timestamp > _periodTime) {
            uint256 prevWeekTime = _periodTime;
            uint256 weekTime = _min(((_periodTime + WEEK) / WEEK) * WEEK, block.timestamp);

            for (uint256 i; i < 500; ) {
                uint256 dt = weekTime - prevWeekTime;
                uint256 w = IGaugeController(_controller).gaugeRelativeWeight(
                    address(this),
                    (prevWeekTime / WEEK) * WEEK
                );

                if (_workingSupply > 0) {
                    if (prevFutureEpoch >= prevWeekTime && prevFutureEpoch < weekTime) {
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _integrateInvSupply += (rate * w * (prevFutureEpoch - prevWeekTime)) / _workingSupply;
                        rate = newRate;
                        _integrateInvSupply += (rate * w * (weekTime - prevFutureEpoch)) / _workingSupply;
                    } else {
                        _integrateInvSupply += (rate * w * dt) / _workingSupply;
                    }
                    // On precisions of the calculation
                    // rate ~= 10e18
                    // last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // The largest loss is at dt = 1
                    // Loss is 1e-9 - acceptable
                }

                if (weekTime == block.timestamp) break;
                prevWeekTime = weekTime;
                weekTime = _min(weekTime + WEEK, block.timestamp);

                unchecked {
                    ++i;
                }
            }
        }

        ++_period;
        period = _period;
        periodTimestamp[_period] = block.timestamp;
        integrateInvSupply[_period] = _integrateInvSupply;

        // Update user-specific integrals
        integrateFraction[addr] += (_workingBalance * (_integrateInvSupply - integrateInvSupplyOf[addr])) / 1e18;
        integrateInvSupplyOf[addr] = _integrateInvSupply;
        integrateCheckpointOf[addr] = block.timestamp;
    }
}
