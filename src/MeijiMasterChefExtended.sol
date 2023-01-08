pragma solidity ^0.8.14;

import "./MeijiMasterChef.sol";

// Functions which would otherwise Clutter Masterchef for multi-actions
contract MeijiMasterChefExtended is MeijiMasterChef {
    function multiWithdraw(uint256[] calldata positionIds, uint256[] calldata amounts) external {
        // Update summations only once.
        _updateRewardSummations();

        // Ensure array lengths match.
        uint256 length = positionIds.length;
        if (length != amounts.length) revert MismatchedArrayLengths();

        for (uint256 i = 0; i < length; ) {
            _withdraw(positionIds[i], amounts[i]);

            // Counter realistically cannot overflow.
            unchecked {
                ++i;
            }
        }
    }

    function multiStake(uint256[] calldata positionIds, uint256[] calldata amounts) external {
        // Update summations only once. Note that rewards accumulated when there is no one
        // staking will be lost. But this is only a small risk of value loss if a reward period
        // during no one staking is followed by staking.
        _updateRewardSummations();

        // Ensure array lengths match.
        uint256 length = positionIds.length;
        if (length != amounts.length) revert MismatchedArrayLengths();

        for (uint256 i = 0; i < length; ) {
            _stake(positionIds[i], amounts[i]);

            // Counter realistically cannot overflow.
            unchecked {
                ++i;
            }
        }
    }
}