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

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;
    bool public satisfied;
    

    // Events that will be emitted on changes.
    event LowestBidDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
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
        lowestBid = msg.value;
        lowestBidder = sender;
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
            pendingBids[lowestBidder] += lowestBid;
        }
        
        lowestBidder = sender;
        lowestBid = amount;
        
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


        // 3. Interaction. Transfer the amount of lowest bid to the lowest bidder, and transfer the remainder of ETH to the homeowner
        uint amount = lowestBid.mul(30).div(100);
        
        lowestBidder.transfer(amount);
        
    }
    
    // Homeowner confirms if he is satisfied with the task 
    // after auction ended. 
    function FinishofTask( address payable sender) public payable{
        require(ended, "Please end auction first!");
        require(sender == homeowner, "You are not the homeowner");
        // 2. Effects        
        satisfied = true;
        emit TaskFinished(lowestBidder, true);
        
        // 3. Interaction. Transfer the amount of lowest bid to the lowest bidder, and transfer the remainder of ETH to the homeowner
        token.transfer(lowestBidder, lowestBid);
        lowestBidder.transfer(lowestBid.mul(70).div(100));
        sender.transfer(address(this).balance);
        }
    
    function unFinishofTask( address payable sender) public payable{
        // 2. Effects        
        satisfied = false;
        emit TaskFinished(lowestBidder, false);
        
        // 3. Interaction. Transfer both stake and the remainder of ETH to the homeowner;
        token.transfer(sender, lowestBid);
        sender.transfer(address(this).balance);
        }
    
    
    
    
    // Check the ETH balance of the TaskAuction Contract
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}