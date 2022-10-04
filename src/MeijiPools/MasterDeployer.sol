// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interfaces/IPoolFactory.sol";

/// @dev Custom Errors
error InvalidBarFee();
error ZeroAddress();
error NotWhitelisted();

/// @notice Trident pool deployer contract with template factory whitelist.
/// @author Mudit Gupta.
contract MasterDeployer {
    event DeployPool(address indexed factory, address indexed pool, bytes deployData);
    event AddToWhitelist(address indexed factory);
    event RemoveFromWhitelist(address indexed factory);
    event BarFeeUpdated(uint256 indexed barFee);
    event BarFeeToUpdated(address indexed barFeeTo);

    uint256 public barFee;
    address public barFeeTo;

    uint256 internal constant MAX_FEE = 10000; // @dev 100%.

    mapping(address => bool) public pools;
    mapping(address => bool) public whitelistedFactories;

    constructor(
        uint256 _barFee,
        address _barFeeTo
    ) {
        if (_barFee > MAX_FEE) revert InvalidBarFee();
        if (_barFeeTo == address(0)) revert ZeroAddress();

        barFee = _barFee;
        barFeeTo = _barFeeTo;
    }

    function deployPool(address _factory, bytes calldata _deployData) external returns (address pool) {
        if (!whitelistedFactories[_factory]) revert NotWhitelisted();
        pool = IPoolFactory(_factory).deployPool(_deployData);
        pools[pool] = true;
        emit DeployPool(_factory, pool, _deployData);
    }

    function addToWhitelist(address _factory) external {
        whitelistedFactories[_factory] = true;
        emit AddToWhitelist(_factory);
    }

    function removeFromWhitelist(address _factory) external {
        whitelistedFactories[_factory] = false;
        emit RemoveFromWhitelist(_factory);
    }

    function setBarFee(uint256 _barFee) external {
        if (_barFee > MAX_FEE) revert InvalidBarFee();
        barFee = _barFee;
        emit BarFeeUpdated(_barFee);
    }

    function setBarFeeTo(address _barFeeTo) external {
        barFeeTo = _barFeeTo;
        emit BarFeeToUpdated(_barFeeTo);
    }
}

