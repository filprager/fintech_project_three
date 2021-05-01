pragma solidity ^0.5.0;

import "./AirToken.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";

contract AirTokenSale is Crowdsale, MintedCrowdsale {

    constructor(
        uint rate, // rate in TKNbits
        address payable wallet, // sale beneficiary
        AirToken token // the ArcadeToken itself that the ArcadeTokenSale will work with
    )
        Crowdsale(rate, wallet, token)
        public
    {
        // constructor can stay empty
    }
}

contract AirTokenSaleDeployer {

    address public air_sale_address;
    address public token_address;

    constructor(
        string memory name,
        string memory symbol,
        address payable wallet // this address will receive all Ether raised by the sale
    )
        public
    {
        // create the AirToken and keep its address handy
        AirToken token = new AirToken(0);
        token_address = address(token);

        // create the ArcadeTokenSale and tell it about the token
        AirTokenSale arcade_sale = new AirTokenSale(1, wallet, token);
        air_sale_address = address(air_sale);

        // make the ArcadeTokenSale contract a minter, then have the ArcadeTokenSaleDeployer renounce its minter role
        token.addMinter(air_sale_address);
        token.renounceMinter();
    }
}

