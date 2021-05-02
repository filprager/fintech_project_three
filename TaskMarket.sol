pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./TaskAuction.sol";
import "./AirTokenMintable.sol";
import "./AirTokenSale.sol";

contract TaskMarket is ERC721Full, Ownable {
    AirToken public token;
    AirTokenSale air_sale;
    
    constructor() ERC721Full("TaskMarket", "TASK") public {
           // create the ArcadeToken and keep its address handy
        token = new AirToken('Air Token', 'AIRT', 0);
        

        // create the ArcadeTokenSale and tell it about the token
        air_sale = new AirTokenSale(1000000000, msg.sender, token);
        

        // make the ArcadeTokenSale contract a minter, then have the ArcadeTokenSaleDeployer renounce its minter role
        token.addMinter(address(air_sale));
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
        auctions[token_id] = new TaskAuction(homeowner, address(token));
    }

    function registerTask(string memory uri, address payable homeowner) public payable {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id, homeowner);
        safeTransferFrom(owner(), homeowner, token_id);
    }

    // End the auction and transfer 30% of the lowest bid amound to the lowest bidder as a commencement payment
    function endAuction(uint token_id) public taskRegistered(token_id) {
        TaskAuction auction = auctions[token_id];
        auction.auctionEnd(msg.sender);
        safeTransferFrom(msg.sender, auction.lowestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view taskRegistered(token_id)  returns(bool) {
        TaskAuction auction = auctions[token_id];
        return auction.ended();
    }
    
    function finishoftask(uint token_id) public taskRegistered(token_id) {
        
        TaskAuction auction = auctions[token_id];
        auction.FinishofTask(msg.sender);}
   
    function unfinishoftask(uint token_id) public taskRegistered(token_id) {
        require(msg.sender == foundation_address, "you don't have the right to run this function.");
        
        TaskAuction auction = auctions[token_id];
        auction.unFinishofTask(foundation_address);}
    
    function lowestBid(uint token_id) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.lowestBid();
    }

    function pendingDeposit(uint token_id) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.balance();
    }

    function bid(uint token_id, uint amount) public taskRegistered(token_id) {
        
        TaskAuction auction = auctions[token_id];
        token.transferFrom(msg.sender, address(auction), amount);
        auction.bid(msg.sender, amount);
    }
    
    function withdraw(uint token_id) public payable taskRegistered(token_id) {
        TaskAuction auction = auctions[token_id];
        auction.withdraw(msg.sender);
    }
    // Pay ETH to the TaskAuction contract as a deposit that is equal to the maximum price the homeowner is willing to pay
    // Set up the max price by bidding with the deposit amount

    function deposit(uint token_id) public payable taskRegistered(token_id) {
        require(msg.value > 0, "Your deposit needs to be greater than 0");
        TaskAuction auction = auctions[token_id];
        auction.deposit.value(msg.value)(msg.sender);
    }
    
    function pendingBids(uint token_id, address sender) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.pendingBid(sender);
    }

    // Buy Air Tokens by ETH
    function recharge() public payable {
        // uint amount = msg.value.mul(90).div(100);
        air_sale.buyTokens.value(msg.value)(msg.sender);
    }
    
   
    // Check the balance of Air Token 
    function balance_air() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }
}




