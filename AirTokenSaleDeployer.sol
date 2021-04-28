pragma solidity ^0.5.0;

import "./AirTokenMintable.sol";
import "./AirTokenSale.sol";

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
        AirToken token = new AirToken(name, symbol, 0);
        token_address = address(token);

        // create the AirTokenSale and tell it about the token
        AirTokenSale air_sale = new AirTokenSale(1, wallet, token);
        air_sale_address = address(air_sale);

        // make the AirTokenSale contract a minter, then have the AirTokenSaleDeployer renounce its minter role
        token.addMinter(air_sale_address);
        token.renounceMinter();
    }
}