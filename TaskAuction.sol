pragma solidity >=0.4.22 <0.6.0;

contract TaskAuction {
    address payable public homeowner;

    // Current state of the auction.
    address payable public lowestBidder;
    uint public lowestBid;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingBids;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public locked;
    bool public finished;

    // Events that will be emitted on changes.
    event LowestBidDecreased(address bidder, uint amount);
    event AuctionLocked(address winner, uint amount);
    event TaskFinished(address winner);
    
    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        address payable _homeowner
    ) public {
        homeowner = _homeowner;
    }

    // Pay ETH to the TaskAuction contract as a deposit
    function deposit(address payable sender) public payable {
        require(sender == homeowner, "You cannot deposit into this auction!");
        require(!locked, "auctionLock has already been called.");
        lowestBid = msg.value;
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

        require(!locked, "Auction has already been locked.");
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

    // / End the auction and send the lowest bid
    // / to the beneficiary.
    // function auctionEnd(address payable sender) public payable {
    //     // It is a good guideline to structure functions that interact
    //     // with other contracts (i.e. they call functions or send Ether)
    //     // into three phases:
    //     // 1. checking conditions
    //     // 2. performing actions (potentially changing conditions)
    //     // 3. interacting with other contracts
    //     // If these phases are mixed up, the other contract could call
    //     // back into the current contract and modify the state or cause
    //     // effects (ether payout) to be performed multiple times.
    //     // If functions called internally include interaction with external
    //     // contracts, they also have to be considered interaction with
    //     // external contracts.

    //     // 1. Conditions
    //     require(!ended, "auctionEnd has already been called.");
    //     require(sender == homeowner, "You are not the auction beneficiary");

    //     // 2. Effects
    //     ended = true;
    //     emit AuctionEnded(lowestBidder, lowestBid);


    //     // 3. Interaction. Transfer the amount of lowest bid to the lowest bidder, and transfer the remainder of ETH to the homeowner
    //     lowestBidder.transfer(lowestBid);
    //     sender.transfer(address(this).balance);
    // }
    
    function auctionLock(address payable sender) public payable {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions
        require(!locked, "Auction has already been locked.");
        require(sender == homeowner, "You are not the auction beneficiary");

        // 2. Effects
        locked = true;
        emit AuctionLocked(lowestBidder, lowestBid);
    }
    
    function confirmFinishOfTask(address payable sender) public payable {
        // 1. Conditions
        require(locked, "Auction has not been locked.");
        require(sender == homeowner, "You are not the auction beneficiary");
        
        // 2. Effects        
        finished = true;
        emit TaskFinished(lowestBidder);
        
        // 3. Interaction. Transfer the amount of lowest bid to the lowest bidder, and transfer the remainder of ETH to the homeowner
        lowestBidder.transfer(lowestBid);
        sender.transfer(address(this).balance);
    }     
    
    // Check the ETH balance of the TaskAuction Contract
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}