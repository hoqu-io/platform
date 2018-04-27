pragma solidity ^0.4.16;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './HoQuToken.sol';

/**
 * @title HoQuBurner
 * @title HoQu.io contract to burn HQX.
 */
contract HoQuBurner is Ownable {
    using SafeMath for uint256;

    // token instance
    HoQuToken public token;

    mapping(address => uint256) public burned;
    mapping(uint32 => address) public transactionAddresses;
    mapping(uint32 => uint256) public transactionAmounts;
    uint32 public transactionsCount;

    /**
    * Events for token burning
    */
    event TokenBurned(address indexed _sender, uint256 _tokens);

    /**
    * @param _tokenAddress address of a HQX token contract
    */
    function HoQuBurner(address _tokenAddress) {
        token = HoQuToken(_tokenAddress);
    }

    /**
     * Burn particular HQX amount already sent to this contract
     *
     * Should be executed by contract owner (for security reasons).
     * Sender should just send HQX tokens to contract address
     */
    function burnFrom(address _sender, uint256 _tokens) onlyOwner {
        require(_tokens > 0);

        token.transfer(address(0), _tokens);

        transactionAddresses[transactionsCount] = _sender;
        transactionAmounts[transactionsCount] = _tokens;
        transactionsCount++;

        burned[_sender] = burned[_sender].add(_tokens);

        TokenBurned(_sender, _tokens);
    }

    /**
     * Burn particular HQX amount using token allowance
     *
     * Should be executed by sender.
     * Sender should give allowance for specified amount in advance (see approve method of HOQU token contract)
     */
    function burn(uint256 _tokens) {
        token.transferFrom(msg.sender, this, _tokens);
        burnFrom(msg.sender, _tokens);
    }
}