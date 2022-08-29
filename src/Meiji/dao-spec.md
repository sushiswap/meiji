# Meiji DAO Spec

The Meiji DAO is Sushi's latest iteration, combining decentralized governace with a new mode of operations. 

## Overall Design

The Sushi Meiji DAO will be replacing legacy govnerance structures, and so to do this many adaptions will be needed.

## Description

### Membership

- Meiji DAO Contracts will allow entrance into the DAO by locking up SUSHI and granting shares according with `Shares granted = sqrt(SUSHI Locked up) / log(sqrt(Total Members))`
- An Initiation Period then begins after locking up SUSHI until you realize the voting power from the gained shares, of double the voting period.
- Each Member of the DAO will have a voting weight assosiated with them, an exile status (if they've been kicked out nulling their voting power), and a public key assosiated with their voting.
- A vote can be started to exile a Member, requiring quroum and a 70% majority.
- Exiled members can leave claiming their SUSHI, but cannot rejoin.
- Ragequit will always be an option to forfeit voting power to claim underlying SUSHI
- Each Member will also have a High Kitchen Status indicating whether they are a part of the High Kitchen

### Operations
- The DAO will have the ability to operate across Ethereum Rollups to enable cheap governance participation, although canonical bridge wait times for Optimism and Arbitrum which will slow down the finality of proposals.
- The DAO will have an Action Enum which has basic wrappers to make things like ERC20 transfers and other actions easier. Also actions for things like Salary (which once a salary passed it must be voted to stop the salary, which will otherwise auto-renew) to stop members backpay. Salary should initially route through Sushi Furo.
- The Highkitchen can with a majority vote turn on a flag on a Proposal to veto it. 

### DAO Treasury

The existing SUSHI DAO treausry will slowly be migrated to the new Meiji DAO, with security watching as it slowly moves over. Funds will be streamed to the new Meiji DAO at a rate of 30% above current operations costs, this is done so that Meiji DAO can allocate funding, but will not be given full financial control until it stablizes.

The DAO can also have a strategy at rest or similar treasury management strategies, which can be allocated by percentage points. Otherwise assets are held by default.

## Contract Design

Unlike Moloch which leverages a Factory Pattern Meiji DAO stands alone as it's own contract system. To allow for the unexpected conditions where the DAO may wish to modify it's own code a modular system is designed.

## ConsensusModule

The overall purpose and goal of ConsensusModule is to handle user registration and keep track of what the DAO want's to accomplish. The overall pipeline of this module should be user interaction resulting in an Action struct. The Consensus Module is just focused on achieving consensus on what actions it should undertake.

### Enter/Exiting

`function enter(uint256 tokensIn) external returns (uint256)`

This function should allow non-blacklisted users to enter the DAO, and return the number of shares granted to them. The parameter indicates how many tokens the user is locking up, in this case how many SUSHI should be locked in the DAO. Shares should then be granted along the formula of `Shares granted = sqrt(Additional Sushi they are locking up) / log(sqrt(Total Members))`. It is important to note that shares do not change as more members join, so it is possible for a user to recieve shares at 2 different rates if they lock up at 2 different times, if the amount of shares granted per SUSHI goes down with time though, their initial shares remain the same and **will not decay**.

Users shares shouldn't be granted voting powers though until 2 times the voting period passes from their entrance.

`function exit(uint8 percentOut) external returns (uint256)`

This function should allow anyone to exit the Meiji DAO, but importantly the input is in the percentage they wish to withdraw, which will reduce their shares by that percent. Rounding will done upwards (removing more shares than less) to err on the side of caution, and percent is scaled to 0 decimals.

Exiting is an atomic and instant process, and is assured safe because re-entering carries a time-delay with it.

### Proposal Posting
