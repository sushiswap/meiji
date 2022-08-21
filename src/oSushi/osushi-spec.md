# oSushi Spec

oSushi will be Sushi’s new veToken system focused around building sustainability into the SUSHI Token.

## Sushi Gauges

oSushi will recieve 90% of xSushi fee revenues, these fees will be auctioned off for SUSHI which will then be added on top of emissions.

## oSUSHI

### Overview

* oSushi stands for Onsen Sushi and it is a ERC-20 token but non-transferrable.
* With oSUSHI, you can vote for gauge weights to decide which pool will receive more SUSHI and fee emissions.
* Your oSUSHI balance decays linearly every week.
    * Increase amount: If you lock up more SUSHI the unlock time remains the same.
    * Increase period: You can also increase your lock-up period up to a maximum of 4 years, which will decrease the rate at which your oSushi decays.
* You can choose to delegate your oSushi to someone else, but this delegation is one-time and cannot be changed until your vesting term ends
* You can unlock your SUSHI, doing so will impose a penalty of 50%, which will then be distributed through the Gauges as extra emissions.

### Interface

```solidity
    /**
     * @notice Get the current voting power for `msg.sender`
     * @param addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address addr, uint256 _t) public view returns (uint256);
```

```solidity
    /**
     * @notice Measure voting power of `addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);
```

```solidity
    /**
     * @notice Calculate total voting power
     * @return Total voting power
     */
    function totalSupply(uint256 t) public view returns (uint256);
```

```solidity
    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);
```

```solidity
    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external override;
```

```solidity
    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     */
    function depositFor(address _addr, uint256 _value) external override;
```

```solidity
    /**
     * @notice Deposit `_value` tokens for `_addr` and lock for `_duration`
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     * @param _duration Epoch time until tokens unlock from now
     */
    function createLockFor(
        address _addr,
        uint256 _value,
        uint256 _duration
    ) external override;
```

```solidity
    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _addr User's wallet address
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmountFor(address _addr, uint256 _value) external override;
```

```solidity
    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value) external {
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }
```

```solidity
    /**
     * @notice Extend the unlock time for `msg.sender` to `_duration`
     * @param _duration Increased epoch time for unlocking
     */
    function increaseUnlockTime(uint256 _duration) external override;
```

```solidity
    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value) external {
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }
```

```solidity
    /**
     * @notice Cancel the existing lock of `msg.sender` with 50% penalty
     * @dev Only possible if the lock exists
     */
    function cancel() external override;
```

```solidity
    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override;
```

```solidity
    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value) external {
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }
```

## GaugeController

### Overview

- GaugeController Maintains a list of all pools eligble for SUSHI emmissions across all chains. Interface for pools should be compliant with Uni V2 Pools and Tridnet Pools.
- oSushi holders can vote in this contract which Pool they believe should recieve emmissions.
- Votes should not be changeable until the next voting period has begun.
- Determines validity of pools by checking factory, oSushi holders can vote to add factories to the eliligiblity list

### Interface

```solidity
    /**
     * @notice Get gauge type for id
     * @param addr Gauge address
     * @return Gauge type id
     */
    function gaugeTypes(address addr) external view returns (int128);
```

```solidity
    /**
     * @notice Get current gauge weight
     * @param addr Gauge address
     * @return Gauge weight
     */
    function getGaugeWeight(address addr) external view returns (uint256);
```

```solidity
    /**
     * @notice Get current type weight
     * @param gaugeType Type id
     * @return Type weight
     */
    function getTypeWeight(int128 gaugeType) external view returns (uint256);
```

```solidity
    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);
```

```solidity
    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view returns (uint256);
```

```solidity
    /**
     * @notice Get sum of gauge weights per type
     * @param gaugeType Type id
     * @return Sum of gauge weights
     */
    function getWeightsSumPerType(int128 gaugeType) external view returns (uint256);
```

```solidity
    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr) external view returns (uint256); 
```

```solidity
    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr, uint256 time) public view returns (uint256);
```

```solidity
    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external override;
```

```solidity
    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external override;
```

```solidity
    /**
     * @notice Allocate voting power for changing pool weights on behalf of a user (only called by gauges)
     * @param gaugeAddr Gauge which `msg.sender` votes for
     * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external override;
```

## LiquidityGauge

### Overview

- LiquidityGauges are responsible for keeping track of votes for a specific pool, and how many emissions should be signaled towards a specific pool.
- Each LiquidityGauge is tied to a pool, which requires users to lock up their LP tokens.
- LiquidityGauge can be registered with GaugeController to be eligble for rewards.
- Liquidity providers need to deposit their LP tokens to the corresponding LiquidityGauge to receive SUSHI rewards.
- LPs can boost up their rewards up to 2.5x by voting for pools in GaugeController using oSUSHI tokens.

### Interface

```solidity
    /**
     * @notice The current amount of LP tokens that addr has deposited into the gauge.
     */
    function balanceOf(address account) external view returns (uint256);
```

```solidity
    /**
     * @notice The "working balance" of a user - their effective balance after boost has been applied.
     */
    function workingBalances(address addr) external view returns (uint256);
```

```solidity
    /**
     * @notice The amount of currently mintable SUSHI for addr from this gauge.
     */
    function claimableTokens(address addr) external returns (uint256);
```

```solidity
    /**
     * @notice The total amount of SUSHI, both mintable and already minted, that has been allocated to addr from this gauge.
     */
    function integrateFraction(address user) external view returns (uint256);
```

```solidity
    /**
     * @notice Record a checkpoint for addr, updating their boost.
     * Only callable by addr or Minter - you cannot trigger a checkpoint for another user.
     */
    function userCheckpoint(address user) external returns (bool);
```

```solidity
    /**
     * @notice Trigger a checkpoint for addr. 
     * Only callable when the current boost for addr is greater than it should be, due to an expired oSUSHI lock.
     */
    function kick(address addr) external;
```

```solidity
    /**
     * @notice Deposit LP tokens into the gauge.
     * Prior to depositing, ensure that the gauge has been approved to transfer amount LP tokens on behalf of the caller.
     * @param _value: Amount of tokens to deposit
     * @param addr: Address to deposit for. If not given, defaults to the caller.
     */
    function deposit(uint256 _value, address addr) external;
```

```solidity
    /**
     * @notice Withdraw LP tokens from the gauge.
     * @param _value: Amount of tokens to withdraw
     */
    function withdraw(uint256 _value) external;
```

```solidity
    /**
     * @notice Toggle the killed status of the gauge.
     * This function may only be called by the ownership or emergency admins within the DAO.
     * A gauge that has been killed is unable to mint SUSHI. Any gauge weight given to a killed gauge effectively burns SUSHI. This should only be done in a case where a pool had to be killed due to a security risk, but the gauge was already voted in.
     */
    function killMe() external;
```

```solidity
    /**
     * @notice The current killed status of the gauge.
     */
    function isKilled() external view returns (bool);
```

## Minter

### Overview

- The Minter contract will have the minting of new SUSHI’s to signaled gauges.
- The Minter contract will be unable to actually facilitate minting of new tokens, so instead a MasterChef adapter will be written. Masterchef will view Minter as the only pool, wiht max boost, and will direct all new SUSHI emissions to the Minter contract, so that it can then re-distribute them.

### Interface

```solidity
    /**
     * @notice The current amount of LP tokens that addr has deposited into the gauge.
     */
    function mint(address gaugeAddr) external;
```

```solidity
    /**
     * @notice The "working balance" of a user - their effective balance after boost has been applied.
     */
    function mintMany(address[8] calldata gaugeAddrs) external;
```

```solidity
    /**
     * @notice The amount of currently mintable CRV for addr from this gauge.
     */
    function mintFor(address gauge_address, address _for) external;
```

## Bribe

### Overview

- The Bribe contract auctions off voting power at a rate of SUSHI per vote, allowing people to buy in varying quantities as long as they meet the rate.
- This rate decreases throughout the week in a dutch auction until it is sold out.
- The earned SUSHI is then made immediately avaliable to those who’ve locked up their SUSHI inside of the Canonical Bribe contract.

### Interface

```solidity
    /**
     * @notice The number of rewards that will be earned per 1 LP token
     */
    function rewardsPerToken(address token) public view returns (uint256);
```

```solidity
    /**
     * @notice Total amount of rewards earned so far for `token`
     */
    function totalRewardsEarned(address token) external view returns (uint);
```

```solidity
    /**
     * @notice allows a user to claim rewards.
     */
    function claimRewards(address[] memory tokens) external;
```

