pragma solidity 0.8.15;

import "./interfaces/IGaugeController.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/IERC20.sol";

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
}

contract Minter {
    address public immutable masterChef;
    uint256 public immutable pid;
    address public immutable token;
    address public immutable controller;

    mapping(address => uint256) public balanceOf;

    // Maybe make a double key mapping?
    mapping(address => mapping(address => uint256)) public minted;

    constructor(
        address _masterChef,
        uint256 _pid,
        address _token,
        address _controller
    ) {
        masterChef = _masterChef;
        pid = _pid;
        token = _token;
        controller = _controller;

        balanceOf[address(this)] = 1e18;
    }

    uint256 locked = 1;

    modifier lock() {
        require(locked == 1);

        locked = 2;

        _;

        locked = 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == masterChef);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function initialize() external {
        IMasterChef(masterChef).deposit(pid, 1e18);
    }

    function _mintFor(address gaugeAddr, address _for) internal {
        require(
            IGaugeController(controller).gaugeTypes(gaugeAddr) >= 0,
            "MT: GAUGE_NOT_ALLOWED"
        );

        ILiquidityGauge(gaugeAddr).userCheckpoint(_for);

        uint256 totalMint = ILiquidityGauge(gaugeAddr).integrateFraction(_for);
        uint256 toMint = totalMint - minted[_for][gaugeAddr];

        if (toMint != 0) {
            IMasterChef(masterChef).deposit(pid, 0);
            IERC20(token).transfer(_for, toMint);
            minted[_for][gaugeAddr] = totalMint;
        }
    }

    function mint(address gaugeAddr) external lock {
        _mintFor(gaugeAddr, msg.sender);
    }

    function mintMany(address[8] calldata gaugeAddrs) external lock {
        for (uint256 i = 0; i < gaugeAddrs.length; ++i) {
            if (gaugeAddrs[i] == address(0)) {
                break;
            }
            _mintFor(gaugeAddrs[i], msg.sender);
        }
    }

    function mintFor(address gauge_address, address _for) external lock {
        _mintFor(gauge_address, _for);
    }
}
