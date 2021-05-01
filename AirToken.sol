pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Mintable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";

contract AirToken is ERC20, ERC20Detailed, ERC20Mintable, Ownable {
    address payable owner = msg.sender;

    mapping(address => uint) balances;

    constructor(uint initial_supply) ERC20Detailed("AirToken", "AIR", 18) public {
        
        _mint(msg.sender, initial_supply);
    }
    

   

    function purchase(uint amount) public payable {
        uint amount = msg.value;
        balances[msg.sender] = balances[msg.sender].add(amount);
        owner.transfer(msg.value);
    }


