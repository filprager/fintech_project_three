pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./TaskAuction.sol";

contract TaskMarket is ERC721Full, Ownable {

    constructor() ERC721Full("TaskMarket", "TASK") public {}

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
        TaskAuction auction = auctions[token_id];
        auction.bid(msg.sender, amount);
    }
    
    // Pay ETH to the TaskAuction contract as a deposit that is equal to the maximum price the homeowner is willing to pay
    // Set up the max price by bidding with the deposit amount
    function deposit(uint token_id) public payable{
        require(msg.value > 0, "Your deposit needs to be greater than 0");
        TaskAuction auction = auctions[token_id];
        auction.deposit.value(msg.value)(msg.sender);
       
    }

}