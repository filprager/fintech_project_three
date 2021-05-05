pragma solidity >=0.4.22 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";
import "./AirTokenMintable.sol";

contract TaskAuction {
    using SafeMath for uint;
    address payable public homeowner;

    // Current state of the auction.
    address payable public lowestBidder;
    uint public lowestBid;
    
    // Air token 
    AirToken token;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingBids;
    address[] public addressIndices;
    
    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;
    bool public satisfied;
    bool public finished;

    // Events that will be emitted on changes.
    event LowestBidDecreased(address bidder, uint amount);
    event Budget(address homeowner, uint amount);
    event AuctionEnded(address winner, uint amount);
    event AuctionStopped(address homeowner);
    event TaskFinished(address winner, bool satisfied);
    
    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        address payable _homeowner,
        address tokenAddress
    ) public {
        homeowner = _homeowner;
        token = AirToken(tokenAddress);
    }

    // Pay ETH to the TaskAuction contract as a deposit
    function deposit(address payable sender) public payable {
        require(sender == homeowner, "You cannot deposit into this auction!");
        require(!ended, "auctionEnd has already been called.");
        sender = lowestBidder;
        lowestBid += msg.value;
        emit Budget(sender, msg.value);
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(address payable sender, uint amount) public {
        // If the bid is not higher, send the
        // money back.
        
        require(
            amount < lowestBid, 
            "There already is a lower bid."
        );
        require(sender != homeowner, "You cannot bid on your own task!");

        require(!ended, "auctionEnd has already been called.");
        
        
        
        if (lowestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingBids[sender] += amount;
        }
        
        lowestBidder = sender;
        lowestBid = amount;
        addressIndices.push(lowestBidder);
        emit LowestBidDecreased(sender, amount);
    }
    /// Withdraw a bid that was overbid.
    function withdraw(address payable sender) public {
        require(sender != lowestBidder, "You cannot withdraw your stake!");
        
        uint amount = pendingBids[sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingBids[sender] = 0;
            token.transfer(sender, amount);
        
        }
    }
    
    function pendingBid(address sender) public view returns (uint) {
        return pendingBids[sender];
    }

  
    /// End the auction and send the lowest bid
    /// to the beneficiary.
    function auctionEnd(address payable sender) public payable {
  
        // 1. Conditions
        require(!ended, "auctionEnd has already been called.");
        require(sender == homeowner, "You are not the auction beneficiary");

        // 2. Effects
        ended = true;
        emit AuctionEnded(lowestBidder, lowestBid);


        // 3. Interaction. 
        // Transfer the delta back to Homeowner
        // Transfer 30% of the lowest bid amount to the lowest bidder as a commencement payment
        sender.transfer(address(this).balance.sub(lowestBid));
        uint amount = lowestBid.mul(30).div(100);
        lowestBidder.transfer(amount);
        
    }
    
    function auctionStop(address payable sender) public payable {
  
        // 1. Conditions
        require(!ended, "auctionEnd has already been called.");
        require(sender == homeowner, "You are not the auction beneficiary");
        
        // 2. Effects
        ended = true;

        // 3. Interaction. 
         
        for (uint i=0; i < addressIndices.length; i++) {
            uint amount = pendingBid(addressIndices[i]);
            if (amount > 0) {
                pendingBids[addressIndices[i]] =0;
                token.transfer(addressIndices[i], amount);}
        }
        sender.transfer(address(this).balance);
        emit AuctionStopped(sender); 
    }  
    
    // Homeowner confirms if he is satisfied with the task 
    // after auction ended. 
    function FinishofTask( address payable sender) public payable{
        require(ended, "Please end auction first!");
        require(sender == homeowner, "You are not the homeowner");
        // 2. Effects
        finished = true;
        satisfied = true;
        emit TaskFinished(lowestBidder, true);
        
        // 3. Interaction
        // Return Air Token back to the lowest bidder 
        // Transfer the remaining 70% of the lowest bid amount (ETH) to the lowest bidder
        // Return the remainder of deposit (ETH) back to the homeowner
        token.transfer(lowestBidder, lowestBid);
        lowestBidder.transfer(lowestBid.mul(70).div(100));
        sender.transfer(address(this).balance);
        }
    
    function unFinishofTask( address payable sender) public payable{
        require(ended, "Please end auction first!");

        // 2. Effects
        finished = true; 
        satisfied = false;
        emit TaskFinished(lowestBidder, false);
        
        // 3. Interaction. Lock the Air Token and ETH;
        token.transfer(sender, lowestBid);
        sender.transfer(address(this).balance);
        }
    
    
    // Check the ETH balance of the TaskAuction Contract
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}