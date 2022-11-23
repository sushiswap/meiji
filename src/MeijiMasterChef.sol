pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";

contract MeijiMasterChef {
    IERC20 public immutable RewardToken;
    uint256 public constant PRECISION = 2 ** 128;

    /* Error Messages */
    error NoEffect();
    error Overflow();
    error InsufficientBalance();

    struct RewardParameters {
        uint80 _rewardRate; // Rewards per second in a reward period
        uint40 periodFinish;
        uint40 lastUpdate;
    }

    RewardParameters public RewardVariables;

    struct ValueVariables {
        // The amount of tokens staked in the position or the contract.
        uint96 balance;
        // The sum of each staked token in the position or contract multiplied by its update time.
        uint160 sumOfEntryTimes;
    }

    ValueVariables public totalValueVariables;

    struct RewardSummations {
        // Imaginary rewards accrued by a position with `lastUpdate == 0 && balance == 1`. 
        uint256 idealPosition;
        // The sum of `reward/totalValue` of each interval. `totalValue` is the sum of all staked
        // tokens multiplied by their respective staking durations. 
        uint256 rewardPerValue;
    }

    RewardSummations public rewardSummationsStored;

    struct Account {
        // Two variables that determine the share of rewards a position receives.
        ValueVariables valueVariables;
        // Summations snapshotted on the last update of the position.
        RewardSummations rewardSummationsPaid;
        // The sum of values (`balance * (block.timestamp - lastUpdate)`) of previous intervals
        uint160 previousValues;
        // The last time the position was updated.
        uint48 lastUpdate;
    }

    mapping(address => mapping(uint8 => Account)) public accounts;

    constructor(IERC20 _RewardToken) {
        RewardToken = _RewardToken;
    }

    function _updateRewardSummations() internal {
        uint256 _PeriodFinish = RewardVariables.periodFinish;

        // Get end of the reward distribution period or block timestamp, whichever is less.
        uint256 lastTimeRewardApplicable = _PeriodFinish < block.timestamp ? _PeriodFinish : block.timestamp;

        // For efficiency, move lastUpdate timestamp to memory. `lastUpdate` is the beginning
        // timestamp of the period we are calculating the total rewards for.
        uint256 _lastUpdate = RewardVariables.lastUpdate;

        uint256 rewards;
        // If the reward period is a positive range, return the rewards by multiplying the duration
        // by reward rate.
        if (lastTimeRewardApplicable > _lastUpdate) {
            unchecked {
                rewards = (lastTimeRewardApplicable - _lastUpdate) * RewardVariables._rewardRate;
            }
        } else {
            return; // If rewards = 0, then there are no summations to update
        }

        assert(rewards <= type(uint96).max);

        // Update last update time.
        RewardVariables.lastUpdate = uint40(block.timestamp);

        // Get incrementations based on the reward amount.
        uint256 idealPositionIncrementation = 0;
        uint256 rewardPerValueIncrementation = 0;
        // Calculate the totalValue, then get the incrementations only if value is non-zero.
        uint256 totalValue = block.timestamp * totalValueVariables.balance - totalValueVariables.sumOfEntryTimes;
        if (totalValue == 0) {
            return; // If totalValue is 0, then no more incrementations are needed
        }

        idealPositionIncrementation = (rewards * block.timestamp * PRECISION) / totalValue;
        rewardPerValueIncrementation = (rewards * PRECISION) / totalValue;

        rewardSummationsStored.idealPosition += idealPositionIncrementation;
        rewardSummationsStored.rewardPerValue += rewardPerValueIncrementation;
    }

    function _pendingRewards(Account storage position) internal view returns (uint256) {
        // Get the change in summations since the position was last updated. When calculating
        // the delta, do not increment `rewardSummationsStored`, as they had to be updated anyways.
        RewardSummations memory deltaRewardSummations;
        RewardSummations storage rewardSummationsPaid = position.rewardSummationsPaid;

        uint256 idealPositionDelta = rewardSummationsStored.idealPosition - rewardSummationsPaid.idealPosition;
        uint256 idealRewardDelta = rewardSummationsStored.rewardPerValue - rewardSummationsPaid.rewardPerValue;

        deltaRewardSummations = position.lastUpdate == 0 ? RewardSummations(0, 0) : RewardSummations(idealPositionDelta, idealRewardDelta);

        // Return the pending rewards of the position.
        if (position.lastUpdate == 0) return 0;

        uint256 differenceFromIdeal = (deltaRewardSummations.idealPosition - (deltaRewardSummations.rewardPerValue * position.lastUpdate));
        uint256 pendingRewards = (differenceFromIdeal * position.valueVariables.balance ) + (deltaRewardSummations.rewardPerValue * position.previousValues);

        return pendingRewards / PRECISION;
    }

    function _stake(uint8 index, address owner, uint256 amount) internal {
        Account storage position = accounts[owner][index];
        // Total Amount to be staked includes pending rewards
        uint256 totalAmount = amount +  _pendingRewards(position);
        if (totalAmount == 0) revert NoEffect();

        // Get the new total staked amount and ensure it fits 96 bits.
        uint256 newTotalStaked = totalValueVariables.balance + totalAmount;
        if (newTotalStaked > type(uint96).max) revert Overflow();

        unchecked {
            // Increment the state variables pertaining to total value calculation.
            uint160 addedEntryTimes = uint160(block.timestamp * totalAmount);
            totalValueVariables.sumOfEntryTimes += addedEntryTimes;
            totalValueVariables.balance = uint96(newTotalStaked);

            // Increment the position properties pertaining to position value calculation.
            ValueVariables storage positionValueVariables = position.valueVariables;
            uint256 oldBalance = positionValueVariables.balance;
            positionValueVariables.balance = uint96(oldBalance + totalAmount);
            positionValueVariables.sumOfEntryTimes += addedEntryTimes;

            // Increment the previousValues.
            position.previousValues += uint160(oldBalance * (block.timestamp - position.lastUpdate));
        }

        // Snapshot the lastUpdate and summations.
        position.lastUpdate = uint48(block.timestamp);
        position.rewardSummationsPaid = rewardSummationsStored;

        // Transfer amount tokens from user to the contract, and emit the associated event.
        if (amount != 0) RewardToken.transferFrom(msg.sender, address(this), amount);
    }

    function _withdraw(uint8 index, address owner, uint256 amount) internal {
        // Create a storage pointer for the position.
        Account storage position = accounts[owner][index];

        // Get position balance and ensure sufficient balance exists.
        uint256 oldBalance = position.valueVariables.balance;
        if (amount > oldBalance) revert InsufficientBalance();

        // Get accrued rewards of the position and get totalAmount to withdraw (incl. rewards).
        uint256 reward = _pendingRewards(position);
        uint256 totalAmount = amount + reward;
        if (totalAmount == 0) revert NoEffect();

        unchecked {
            // Get the remaining balance in the position.
            uint256 remaining = oldBalance - amount;

            // Decrement the withdrawn amount from totalStaked.
            totalValueVariables.balance -= uint96(amount);

            // Update sumOfEntryTimes.
            uint256 newEntryTimes = block.timestamp * remaining;
            ValueVariables storage positionValueVariables = position.valueVariables;
            totalValueVariables.sumOfEntryTimes =
                uint160(totalValueVariables.sumOfEntryTimes + newEntryTimes - positionValueVariables.sumOfEntryTimes);

            // Decrement the withdrawn amount from position balance and update position entryTimes.
            positionValueVariables.balance = uint96(remaining);
            positionValueVariables.sumOfEntryTimes = uint160(newEntryTimes);
        }

        // Reset the previous values, as we have restarted the staking duration.
        position.previousValues = 0;

        // Snapshot the lastUpdate and summations.
        position.lastUpdate = uint48(block.timestamp);
        position.rewardSummationsPaid = rewardSummationsStored;

        // Transfer withdrawn amount and rewards to the user, and emit the associated event.
        RewardToken.transfer(msg.sender, amount);
    }

    function stake(uint8 account, uint256 amount) external {
        // Update summations. Note that rewards accumulated when there is no one staking will
        // be lost. But this is only a small risk of value loss when the contract first goes live.
        _updateRewardSummations();
        _stake(account, msg.sender, amount);
    }

    function harvest(uint8 account) external {
        // Update summations that govern the reward distribution.
        _updateRewardSummations();
        // `_withdraw` with zero input amount works as harvesting.
        _withdraw(account, msg.sender, 0);
    }

    function compound(uint8 account) external {
        // Update summations that govern the reward distribution.
        _updateRewardSummations();
        _stake(account, msg.sender, 0); // `_stake` with zero is just compounding
    }

    function withdraw(uint8 account, uint256 amount) external {
        // Update summations that govern the reward distribution.
        _updateRewardSummations();
        _withdraw(account, msg.sender, amount);
    }
}