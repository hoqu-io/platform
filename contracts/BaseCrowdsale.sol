pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './HoQuToken.sol';

/**
 * @title BaseCrowdSale
 * @title HoQu.io base crowdsale contract for managing a token crowdsale.
 */
contract BaseCrowdsale is Pausable {
    using SafeMath for uint256;

    // all accepted ethers go to this address
    address beneficiaryAddress;

    // all remain tokens after ICO should go to that address
    address public bankAddress;

    // token instance
    HoQuToken public token;

    uint256 public maxTokensAmount;
    uint256 public issuedTokensAmount = 0;
    uint256 public minBuyableAmount;
    uint256 public tokenRate; // amount of HQX per 1 ETH
    
    uint256 endDate;

    bool public isFinished = false;

    /**
    * Event for token purchase logging
    * @param buyer who paid for the tokens
    * @param tokens amount of tokens purchased
    * @param amount ethers paid for purchase
    */
    event TokenBought(address indexed buyer, uint256 tokens, uint256 amount);

    modifier inProgress() {
        require (!isFinished);
        require (issuedTokensAmount < maxTokensAmount);
        require (now <= endDate);
        _;
    }
    
    /**
    * @param _tokenAddress address of a HQX token contract
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _beneficiaryAddress accepted ETH go to this address
    * @param _tokenRate rate HQX per 1 ETH
    * @param _minBuyableAmount min ETH per each buy action (in ETH)
    * @param _maxTokensAmount ICO HQX capacity (in HQX)
    * @param _endDate the date when ICO will expire
    */
    function BaseCrowdsale(
        address _tokenAddress,
        address _bankAddress,
        address _beneficiaryAddress,
        uint256 _tokenRate,
        uint256 _minBuyableAmount,
        uint256 _maxTokensAmount,
        uint256 _endDate
    ) {
        token = HoQuToken(_tokenAddress);

        bankAddress = _bankAddress;
        beneficiaryAddress = _beneficiaryAddress;

        tokenRate = _tokenRate;
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
        maxTokensAmount = _maxTokensAmount.mul(1 ether);
    
        endDate = _endDate;
    }

    /*
     * @dev Set new HoQu token exchange rate.
     */
    function setTokenRate(uint256 _tokenRate) onlyOwner inProgress {
        require (_tokenRate > 0);
        tokenRate = _tokenRate;
    }

    /*
     * @dev Set new minimum buyable amount in ethers.
     */
    function setMinBuyableAmount(uint256 _minBuyableAmount) onlyOwner inProgress {
        require (_minBuyableAmount > 0);
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
    }

    /**
     * Buy HQX. Check minBuyableAmount and tokenRate.
     * @dev Performs actual token sale process. Sends all ethers to beneficiary.
     */
    function buyTokens() payable inProgress whenNotPaused {
        require (msg.value >= minBuyableAmount);
    
        uint256 payAmount = msg.value;
        uint256 returnAmount = 0;

        // calculate token amount to be transfered to investor
        uint256 tokens = tokenRate.mul(payAmount);
    
        if (issuedTokensAmount + tokens > maxTokensAmount) {
            tokens = maxTokensAmount.sub(issuedTokensAmount);
            payAmount = tokens.div(tokenRate);
            returnAmount = msg.value.sub(payAmount);
        }
    
        issuedTokensAmount = issuedTokensAmount.add(tokens);
        require (issuedTokensAmount <= maxTokensAmount);

        // send token to investor
        token.transfer(msg.sender, tokens);
        // notify listeners on token purchase
        TokenBought(msg.sender, tokens, payAmount);

        // send ethers to special address
        beneficiaryAddress.transfer(payAmount);
    
        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);
        }
    }

    /**
     * Trigger emergency token pause.
     */
    function pauseToken() onlyOwner returns (bool) {
        require(!token.paused());
        token.pause();
        return true;
    }

    /**
     * Unpause token.
     */
    function unpauseToken() onlyOwner returns (bool) {
        require(token.paused());
        token.unpause();
        return true;
    }
    
    /**
     * Finish ICO.
     */
    function finish() onlyOwner {
        require (issuedTokensAmount >= maxTokensAmount || now > endDate);
        require (!isFinished);
        isFinished = true;
        token.transfer(bankAddress, token.balanceOf(this));
    }
    
    /**
     * Buy HQX. Check minBuyableAmount and tokenRate.
     */
    function() external payable {
        buyTokens();
    }
}