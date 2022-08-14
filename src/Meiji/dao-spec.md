## 🍣 The Meiji DAO

The new Meiji DAO will take inspiration from one of the most successful DAOs to date, MolochDAO. Token-based governance does not work, as has been explained many times by [Vitalik himself](https://vitalik.ca/general/2021/08/16/voting3.html). The Meiji DAO instead works based on shares, which are non-transferable governance rights. Another large improvement of the Meiji DAO it is entirely on chain (with deployment options to Ethereum mainnet or a trusted layer 2), meaning that the Sushi protocol can execute entirely permissionless without buy-in from any organization.

### 🍣 Why/What's Different?

The Meiji DAO provides many improvements over the current one, with one of the main benefits being that governance and operations can move on chain. The Meiji DAO being smart-contract based also allows many exciting new possibilities such as Sushi being able to "sign" smart contracts with other DAOs, own liquidity, and take loans from places like Aave, among many other possibilities.

The Meiji DAO will also see a more decentralized form of governance and put Sushi at the forefront of decentralized governance once again without minority control or proposals requiring buy-in from whales. This will foster community growth which in turn will result in better contributors to push Sushi further.

Gauges will provide a new tokenomics shift investors have been wanting, and work to remedy any current bleeding of token price. Since only 1 year of SUSHI emissions remain, ve economics will prepare Sushi to remain sustainable and thrive in this new environment.


### 🍣 DAO Membership

To prevent Shares from just becoming tokens again, they are granted by locking up SUSHI in an entrance contract (of which you can exit at any time, forfeiting shares), and follow the formula of `Shares granted = sqrt(Total SUSHI you've locked up) / log(sqrt(Total Members))`. This formula was chosen because it results in a distribution similar to that of Quadratic voting, where whales see diminishing returns in shares granted instead of emphasizing the power of the average contributor, but the denominator slows the effectiveness of Sybilers. Additionally, the Meiji DAO is protected from Sybilers since a Member can be kicked out of the DAO for malicious behavior (not disagreements, but Sybiling and other destructive behavior) with a vote where at least 80% are in favor.

This Mechanism is shown below, at different member capacities. (The number in the `log(sqrt (_))` in the denominator is how many members are in the DAO, with the x-axis being SUSHI locked up, and y being shares granted)

![](https://i.imgur.com/2h5gw4T.jpg)

The tables below show shares granted at various thresholds of members and Sushi locked up into the DAO. The result is a mechanism that has some in-built Sybil resistance, which compliments nicely with a minimum share threshold and member slashing to protect the DAO from Sybil or other governance attacks.

| Total Members | 100 Sushi | 5000 Sushi  | 10000 Sushi |
| ------------- | --------- | ----------- | ----------- |
| 100           | 10 shares | 70 shares   | 100 shares  |   
| 1,000         | 6 shares  | 47 shares   | 66 shares   |
| 60,000        | 4 shares  | 29 shares   | 41 shares   |
| 1,000,000     | 3 shares  | 23 shares   | 33 shares   |



Shares are also not granted immediately, and instead, Members must wait for double the voting period before they can vote on proposals. This is designed to prevent new voters from joining the DAO in an attempt to attack or vote through a specific proposal without prior service or participation.

**High Kitchen**

As a final backstop against sybiling and other attacks, an optional "High Kitchen" can be instated made up of trusted community members and contributors. While not granted special voting powers, this "High Kitchen" can veto proposals through the DAO with the intent of this power being used to defend the protocol against governance attacks, or similar vectors which arise from the new DAO being on chain.

It is important to note this High Kitchen will be chosen by the community on the finalization and made up of trusted community Members. The High Kitchen cannot rush through any proposal, nor do they have the power to act on behalf of the DAO. They can merely block proposals from being executed if they are deemed harmful, and a last line of attack.

The idea is to eventually remove the High Kitchen, but as fully autonomous DAOs are a novel concept, it is important to have some operational guardrails in place. This is one of them, so while mechanisms will be built in the DAO to allow the removal of the High Kitchen (such as a majority vote from within the Kitchen), they will remain to protect the DAO at first.

### 🍣 DAO Operations

Since users in the DAO cannot vote on Gauges with their SUSHI locked up, the DAO is funded through 10% of the xSushi fee (the other 90% going to gauges), and 30% of remaining SUSHI emissions (this 30% is granted as SUSHI is emitted, not a chunk all at once). This money is designed to allow the DAO to do things like facilitate development bounties, attend conferences, pay devs, or anything to facilitate the growth of Sushi as a whole.

Proposals on chain will be able to suggest arbitrary `eth_call` actions from the DAO, opening up many new possibilities for governance. Some of the main benefits of this are opening the door for things like protocol-owned liquidity, and Sushi being able to finance from protocols like Aave.

The operational goals for this DAO are to move development to a bounty-style system. So the ideal flow for the Meiji DAO becomes

1. Proposal for a new idea proposed by Member
2. Proposal passed by the DAO
3. DAO posts bounties to implement the idea
4. DAO votes to pass an implementation, paying the developer in the same proposal

Of course, this is an ideal situation, and it will take time before the Sushi DAO operations can reach this level. Meiji will put in place the framework for this to be possible though.

**Bounties**
> While not fully detailed here and a flexible construct, the idea behind bounties is to provide an open way to implement proposals in the Meiji DAO. So if the proposer isn't able to implement their idea, the DAO can then post a "bounty" to implement the proposal. Then approve an implementation once written, and pay the author.

Voting exhaustion is also another issue the Meiji DAO needs to solve (voting on everything pushes people away fast). The Meiji DAO will curb this through 2 configurable parameters, Maximum Weekly proposals, and Maximum Signaled Proposals. When a proposal is made by a Member, it then must be signaled by other members. At an interval to be determined during Parameter Finalization, the top signaled proposals are then brought to the voting block where voting on each one begins. This limits the number of proposals which can be spammed and provides on-chain proposal curation.

### 🍣 Parameter Finalization

If this proposal passes a final vote will still be required to both deploy this new DAO, and to finalize parameters such as voting period, share quorum threshold, minimum share amounts, and any other needed variables. This proposal is to determine whether there is support for the Meiji DAO, but the contracts won't be enacted until a later implementation vote.
