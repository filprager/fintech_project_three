pragma solidity ^0.5.0;

import "./AirTokenMintable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";

contract AirTokenSale is Crowdsale, MintedCrowdsale {

    constructor(
        uint rate, // rate in TKNbits
        address payable wallet, // sale beneficiary
        AirToken token // the AirToken itself that the AirTokenSale will work with
    )
        Crowdsale(rate, wallet, token)
        public
    {
        // constructor can stay empty
    }
}


