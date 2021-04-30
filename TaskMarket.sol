pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./TaskAuction.sol";
import "./AirTokenMintable.sol";
import "./AirTokenSale.sol";

contract TaskMarket is ERC721Full, Ownable {
    address public air_sale_address;
    address public token_address;
    AirToken token;
    AirTokenSale air_sale;

    constructor() ERC721Full("TaskMarket", "TASK") public {
        // Deploy Air Token
        
        // create the AirToken and keep its address handy
        token = new AirToken('Air Token', 'AIRT', 0);
        token_address = address(token);

        // create the AirTokenSale and tell it about the token
        air_sale = new AirTokenSale(1, msg.sender, token);
        air_sale_address = address(air_sale);

        // make the AirTokenSale contract a minter, then have the AirTokenSaleDeployer renounce its minter role
        token.addMinter(air_sale_address);
        token.renounceMinter();
    }

    using Counters for Counters.Counter;

    Counters.Counter token_ids;

    address payable foundation_address = msg.sender;


    mapping(uint => TaskAuction) public auctions;

    modifier taskRegistered(uint token_id) {
        require(_exists(token_id), "Task not registered!");
        _;
    }

     function createAuction(uint token_id, address payable homeowner) public payable {
        auctions[token_id] = new TaskAuction(homeowner);
    }

    function registerTask(string memory uri, address payable homeowner) public payable {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id, homeowner);
        safeTransferFrom(owner(), homeowner, token_id);
    }

    function endAuction(uint token_id) public taskRegistered(token_id) {
        TaskAuction auction = auctions[token_id];
        auction.auctionEnd(msg.sender);
        safeTransferFrom(msg.sender, auction.lowestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        TaskAuction auction = auctions[token_id];
        return auction.ended();
    }

    function lowestBid(uint token_id) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.lowestBid();
    }

    function pendingDeposit(uint token_id) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.balance();
    }

    function bid(uint token_id, uint amount) public taskRegistered(token_id) {
        require(token.balanceOf(msg.sender) >= amount, "Your Air Token balance needs to be greater than your bid");
        TaskAuction auction = auctions[token_id];
        auction.bid(msg.sender, amount);
    }
    
    // Pay ETH to the TaskAuction contract as a deposit that is equal to the maximum price the homeowner is willing to pay, and
    // set up the max price by bidding with the deposit amount
    function deposit(uint token_id) public payable{
        require(msg.value > 0, "Your deposit needs to be greater than 0");
        TaskAuction auction = auctions[token_id];
        auction.deposit.value(msg.value)(msg.sender);
    }
    
    // Buy Air Tokens by ETH
    function recharge() public payable {
        air_sale.buyTokens.value(msg.value)(msg.sender);
    }
    
    // Check the balance of Air Token 
    function balance_air() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }
}






