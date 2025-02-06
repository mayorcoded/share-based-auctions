// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ShareBasedAuctions
 * @dev A contract for conducting share-based auctions of ERC20 tokens.
 */
contract ShareBasedAuctions is UUPSUpgradeable, OwnableUpgradeable {
    bool public ended;
    IERC20 public token;
    uint256 public tokenQuantity;
    uint256 public endTime;

    mapping(address => uint256) public bidShares;
    uint256 public totalShares;

    event AuctionStarted(address indexed token, uint256 quantity, uint256 endTime);
    event BidPlaced(address indexed bidder, uint256 quantity, uint256 price, uint256 shares);
    event AuctionEnded(uint256 totalQuantitySold, uint256 totalSharesSold);
    event WinningWithdrawn(address indexed bidder, uint256 quantity);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner and the auction token.
     * @param _token Address of the ERC20 token to be auctioned.
     */
    function initialize(address _token) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        token = IERC20(_token);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * the proxy contract.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Starts a new auction.
     * @param _quantity Quantity of tokens to auction.
     * @param _duration Duration of the auction in seconds.
     */
    function startAuction(uint256 _quantity, uint256 _duration) external onlyOwner {
        require(!ended, "Auction already ended");
        require(endTime == 0, "Auction already started");
        require(_quantity > 0, "Quantity must be > 0");
        require(_duration > 0, "Duration must be > 0");

        tokenQuantity = _quantity;
        endTime = block.timestamp + _duration;
        token.transferFrom(msg.sender, address(this), _quantity);

        emit AuctionStarted(address(token), _quantity, endTime);
    }

    /**
     * @dev Places a bid in the auction.
     * @param _quantity Quantity of tokens to bid for.
     * @param _price Price per token (in wei).
     */
    function placeBid(uint256 _quantity, uint256 _price) external {
        require(msg.sender != owner(), "Owner cannot bid");
        require(block.timestamp < endTime, "Auction ended");
        require(_quantity > 0, "Quantity must be > 0");
        require(_price > 0, "Price must be > 0");

        uint256 shares = _quantity * _price;
        bidShares[msg.sender] += shares;
        totalShares += shares;

        emit BidPlaced(msg.sender, _quantity, _price, shares);
    }

    /**
     * @dev Ends the auction.
     */
    function endAuction() external {
        require(block.timestamp >= endTime, "Auction not ended");
        require(!ended, "Auction already ended");
        ended = true;

        emit AuctionEnded(tokenQuantity, totalShares);
    }

    /**
     * @dev Withdraws the winning tokens for the caller.
     */
    function withdrawWinnings() external {
        require(ended, "Auction not ended");
        uint256 bidderShares = bidShares[msg.sender];
        require(bidderShares > 0, "No tokens to claim");

        uint256 winningQuantity;
        if (totalShares == 0) {
            winningQuantity = 0;
        } else {
            winningQuantity = (bidderShares * tokenQuantity) / totalShares;
        }

        bidShares[msg.sender] = 0;
        if (winningQuantity > 0) {
            token.transfer(msg.sender, winningQuantity);
        }

        emit WinningWithdrawn(msg.sender, winningQuantity);
    }
}
