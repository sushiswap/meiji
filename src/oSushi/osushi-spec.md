## 🍣 Sushi Gauges

oSushi will recieve 90% of xSushi fee revenues, these fees will be auctioned off for SUSHI which will then be added on top of emissions.

### 🍣 oSUSHI

oSushi stands for Onsen Sushi, as it will now dictate the Onsen Gauges. oSushi will be it's own new token, but unlike other tokens it will be non-transferrable. oSushi is minted when someone locks up Sushi

Unlike SUSHI, this token is non-transferrable, so you can’t buy or sell it. When you lock up your SUSHI you can choose to delegate your oSushi to someone else, but this delegation is one-time and cannot be changed until your vesting term ends (Similar to how Curve works). Also, while you can unlock your SUSHI, doing so will impose a penalty of 50%, which will then be distributed through the Gauges as extra emissions.

Your oSUSHI balance decays linearly every week. If you lock up more SUSHI the unlock time remains the same. You can also increase your lock-up period up to a maximum of 4 years, which will decrease the rate at which your oSushi decays.

With oSUSHI or gauge voting power, you can vote for gauge weights to decide which pool will receive more SUSHI and fee emissions. This is done via the GaugeController contract, as described below.

### 🍣 GaugeController

The GaugeController contracts maintain a list of all the pools that are eligible for SUSHI emissions, across all chains. This also means that each chain could have a different weight, so for example if Optimism or Polygon want to run a liquidity mining program, they can boost weights for pools on their chain. Each chain could have a different weight and as decided by oSushi holders. (For example, the whole Ethereum pools receive 3x boost, polygon ones 2x, optimism ones 1x, etc) Adding pools to this list is also decided on through a vote by oSushi holders. 

oSUSHI holders vote for pools to decide which one should receive more SUSHI emissions. They can use up 100% of their voting power for 1 pool or distribute it across multiple pools. Once their vote is cast for a specific pool, it cannot be changed to a new pool until the next week. 

### 🍣LiquidityGauge

Each pool will have its own LiquidityGauge that users can lock up their LP tokens and this contract is registered as a pool in GaugeController, not the LP token itself. This contract keeps track of which user should get how many newly minted SUSHI with a boost of up to 2.5x in proportional to how many oSUSHI they already locked up.

In short, to receive the maximum emission as an LP, you need to deposit your LP tokens into its corresponding LiquidityGauge contract and vote with as many oSUSHI as possible.

### 🍣 Bribe

Bribe contracts reward voters who voted for gauges with additional tokens on top of SUSHI emissions. One gauge could have multiple Bribes which means voters could receive multiple reward tokens. We could expect each token project encourages their liquidity providers to deposit their LP tokens to LiquidityGauge and vote for their gauge to receive juicy yield.

### 🍣 Minter

This contract will be used as the dummy pool in the mainnet if this proposal passes, to distribute SUSHI for each pool in GaugeController with all the factors in consideration including the emission amount per week, relative gauge weight between pools, and how much LPs got boosted by voting with oSUSHI, etc.
