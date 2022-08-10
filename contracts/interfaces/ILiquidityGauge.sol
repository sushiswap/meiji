// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILiquidityGauge {
    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 originalBalance,
        uint256 originalSupply,
        uint256 workingBalance,
        uint256 workingSupply
    );

    function minter() external view returns (address);

    function lpToken() external view returns (address);

    function controller() external view returns (address);

    function votingEscrow() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function futureEpochTime() external view returns (uint256);

    function workingBalances(address addr) external view returns (uint256);

    function workingSupply() external view returns (uint256);

    function period() external view returns (int128);

    function periodTimestamp(int128 period) external view returns (uint256);

    function integrateInvSupply(int128 period) external view returns (uint256);

    function integrateInvSupplyOf(address user) external view returns (uint256);

    function integrateCheckpointOf(address user) external view returns (uint256);

    function integrateFraction(address user) external view returns (uint256);

    function inflationRate() external view returns (uint256);

    function isKilled() external view returns (bool);

    function integrateCheckpoint() external returns (uint256);

    function userCheckpoint(address user) external returns (bool);

    function claimableTokens(address addr) external returns (uint256);

    function kick(address addr) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function killMe() external;
}
