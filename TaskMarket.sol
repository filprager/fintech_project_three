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

    function registerTask(string memory uri) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
    }

    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new TaskAuction(foundation_address);
    }

    function endAuction(uint token_id) public onlyOwner taskRegistered(token_id) {
        TaskAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.lowestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        TaskAuction auction = auctions[token_id];
        return auction.ended();
    }

    function lowestBid(uint token_id) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.lowestBid();
    }

    function pendingReturn(uint token_id, address sender) public view taskRegistered(token_id) returns(uint) {
        TaskAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }

    function bid(uint token_id, uint amount) public taskRegistered(token_id) {
        TaskAuction auction = auctions[token_id];
        auction.bid(msg.sender, amount);
    }

}
