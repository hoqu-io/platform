pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './HoQuConfig.sol';

contract HoQuTransactor {
    using SafeMath for uint256;

    HoQuConfig public config;
    ERC20 public token;

    event TokenWithdrew(address indexed payerAddress, uint256 amount);
    event TokenSent(address indexed beneficiaryAddress, uint256 amount);

    modifier onlyOwner() {
        require(config.isAllowed(msg.sender));
        _;
    }

    constructor(
        address configAddress,
        address tokenAddress
    ) public {
        config = HoQuConfig(configAddress);
        token = ERC20(tokenAddress);
    }

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuConfig(configAddress);
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        token = ERC20(tokenAddress);
    }

    function withdraw(address payerAddress, uint256 amount) public onlyOwner {
        token.transferFrom(payerAddress, this, amount);

        emit TokenWithdrew(payerAddress, amount);
    }

    function send(address beneficiaryAddress, uint256 amount) public onlyOwner {
        token.transfer(beneficiaryAddress, amount);

        emit TokenSent(beneficiaryAddress, amount);
    }

    function approve(uint256 amount) public {
        token.approve(this, 0);
        token.approve(this, amount);
    }
}