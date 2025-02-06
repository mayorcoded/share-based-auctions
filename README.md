# Share-Based Auction Contract

This project contains a smart contract for conducting share-based auctions of ERC20 tokens on the Ethereum blockchain. The auction mechanism is designed to distribute tokens proportionally based on each bidder's contribution to the total pool of funds.

## Setup

To set up the project, follow these steps:

1. Clone the repository:
   ```
   git clone https://github.com/mayorcoded/share-based-auctions.git
   ```

2. Install the required dependencies:
   ```
   cd share-based-auctions
   npm install
   ```

3. Compile the contracts:
   ```
   npx hardhat compile
   ```
4. Running tests
    ```
    npx hardhat test
    ```

The tests cover various scenarios, including starting and ending auctions, placing bids, withdrawing winnings, and handling edge cases such as zero quantity/price bids and auctions with no bids.

## Design Decisions

The share-based auction mechanism used in this contract was chosen with the following considerations in mind:

1. **Fairness**: The share-based approach ensures that tokens are distributed proportionally based on each bidder's contribution to the total pool of funds. This prevents any single bidder from dominating the auction and encourages participation from a wider range of bidders.

2. **Gas Efficiency**: By calculating shares based on the total contribution (quantity * price) and avoiding the need for sorting bids, the contract minimizes gas consumption. This is particularly important in the context of Ethereum, where gas costs can be a significant factor.

3. **Simplicity**: The share-based mechanism is straightforward to understand and implement. It does not require complex algorithms or data structures, making the contract easier to audit and maintain.

4. **Flexibility**: The contract allows for flexible bid placement, where bidders can specify both the quantity and price of tokens they wish to bid for. This gives bidders more control over their participation in the auction.

5. **Transparency**: The contract emits events for key actions such as auction start, bid placement, auction end, and winnings withdrawal. These events provide transparency and allow external entities to monitor the progress of the auction.

6. **Upgradability**: The contract is designed to be upgradable using the UUPS (Universal Upgradeable Proxy Standard) pattern. This allows for future improvements and bug fixes to be incorporated without requiring users to migrate to a new contract.

While there are alternative auction mechanisms available, such as Dutch auctions or sealed-bid auctions, the share-based approach was chosen for its simplicity, fairness, and gas efficiency. It provides a good balance between the needs of bidders and the constraints of the Ethereum blockchain.
