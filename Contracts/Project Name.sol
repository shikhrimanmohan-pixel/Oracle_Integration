
/SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleIntegration
 * @dev A smart contract that integrates with Chainlink oracles to fetch external data
 * @author Your Name
 */
contract OracleIntegration {
    // State variables
    mapping(string => AggregatorV3Interface) public priceFeeds;
    mapping(string => int256) public lastPrices;
    mapping(string => uint256) public lastUpdated;
    address public owner;
    
    // Events
    event PriceFeedAdded(string symbol, address priceFeed);
    event PriceUpdated(string symbol, int256 price, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validSymbol(string memory symbol) {
        require(address(priceFeeds[symbol]) != address(0), "Price feed not found for this symbol");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner and initializes common price feeds
     */
    constructor() {
        owner = msg.sender;
        
        // Initialize common price feeds for Ethereum mainnet
        // ETH/USD price feed
        priceFeeds["ETH"] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // BTC/USD price feed  
        priceFeeds["BTC"] = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        // LINK/USD price feed
        priceFeeds["LINK"] = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }
    
    /**
     * @dev Core Function 1: Get the latest price for a given asset
     * @param symbol The symbol of the asset (e.g., "ETH", "BTC", "LINK")
     * @return price The latest price with decimals
     * @return decimals The number of decimals in the price
     * @return timestamp The timestamp of the last update
     */
    function getLatestPrice(string memory symbol) 
        public 
        view 
        validSymbol(symbol) 
        returns (int256 price, uint8 decimals, uint256 timestamp) 
    {
        AggregatorV3Interface priceFeed = priceFeeds[symbol];
        
        (, int256 latestPrice, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        
        return (
            latestPrice,
            priceFeed.decimals(),
            updatedAt
        );
    }
    
    /**
     * @dev Core Function 2: Update and store the latest price for a given asset
     * @param symbol The symbol of the asset to update
     * @return success Whether the update was successful
     */
    function updatePrice(string memory symbol) 
        public 
        validSymbol(symbol) 
        returns (bool success) 
    {
        (int256 price, , uint256 timestamp) = getLatestPrice(symbol);
        
        // Store the price and timestamp
        lastPrices[symbol] = price;
        lastUpdated[symbol] = timestamp;
        
        emit PriceUpdated(symbol, price, timestamp);
        
        return true;
    }
    
    /**
     * @dev Core Function 3: Add a new price feed oracle
     * @param symbol The symbol for the new price feed
     * @param priceFeedAddress The Chainlink price feed contract address
     */
    function addPriceFeed(string memory symbol, address priceFeedAddress) 
        public 
        onlyOwner 
    {
        require(priceFeedAddress != address(0), "Invalid price feed address");
        require(address(priceFeeds[symbol]) == address(0), "Price feed already exists for this symbol");
        
        priceFeeds[symbol] = AggregatorV3Interface(priceFeedAddress);
        
        emit PriceFeedAdded(symbol, priceFeedAddress);
    }
    
    /**
     * @dev Get stored price data for a symbol
     * @param symbol The asset symbol
     * @return price The last stored price
     * @return timestamp The timestamp of last update
     */
    function getStoredPrice(string memory symbol) 
        public 
        view 
        validSymbol(symbol) 
        returns (int256 price, uint256 timestamp) 
    {
        return (lastPrices[symbol], lastUpdated[symbol]);
    }
    
    /**
     * @dev Convert price with decimals to a human-readable format
     * @param symbol The asset symbol
     * @return priceInUSD The price in USD (scaled to 2 decimals)
     */
    function getPriceInUSD(string memory symbol) 
        public 
        view 
        validSymbol(symbol) 
        returns (uint256 priceInUSD) 
    {
        (int256 price, uint8 decimals,) = getLatestPrice(symbol);
        
        // Convert to USD with 2 decimal places
        if (decimals >= 2) {
            return uint256(price) / (10 ** (decimals - 2));
        } else {
            return uint256(price) * (10 ** (2 - decimals));
        }
    }
    
    /**
     * @dev Check if a price feed exists for a symbol
     * @param symbol The asset symbol to check
     * @return exists Whether the price feed exists
     */
    function hasPriceFeed(string memory symbol) 
        public 
        view 
        returns (bool exists) 
    {
        return address(priceFeeds[symbol]) != address(0);
    }
    
    /**
     * @dev Transfer ownership of the contract
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) 
        public 
        onlyOwner 
    {
        require(newOwner != address(0), "New owner cannot be zero address");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Get the price feed contract address for a symbol
     * @param symbol The asset symbol
     * @return feedAddress The address of the price feed contract
     */
    function getPriceFeedAddress(string memory symbol) 
        public 
        view 
        validSymbol(symbol) 
        returns (address feedAddress) 
    {
        return address(priceFeeds[symbol]);
    }
}
