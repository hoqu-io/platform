pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './HoQuToken.sol';

/**
 * @title ClaimableCrowdsale
 * @title HoQu.io claimable crowdsale contract.
 */
contract ClaimableCrowdsale is Pausable {
    using SafeMath for uint256;

    // all accepted ethers will be sent to this address
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

    // buffer for claimable tokens
    mapping(address => uint256) public tokens;
    mapping(address => bool) public approved;
    mapping(uint32 => address) internal tokenReceivers;
    uint32 internal receiversCount;

    /**
    * Events for token purchase logging
    */
    event TokenBought(address indexed _buyer, uint256 _tokens, uint256 _amount);
    event TokenAdded(address indexed _receiver, uint256 _tokens, uint256 _equivalentAmount);
    event TokenToppedUp(address indexed _receiver, uint256 _tokens, uint256 _equivalentAmount);
    event TokenSubtracted(address indexed _receiver, uint256 _tokens, uint256 _equivalentAmount);
    event TokenSent(address indexed _receiver, uint256 _tokens);

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
    * @param _minBuyableAmount min ETH per each buy action (in ETH wei)
    * @param _maxTokensAmount ICO HQX capacity (in HQX wei)
    * @param _endDate the date when ICO will expire
    */
    function ClaimableCrowdsale(
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
        minBuyableAmount = _minBuyableAmount;
        maxTokensAmount = _maxTokensAmount;

        endDate = _endDate;
    }

    /*
     * @dev Set new HoQu token exchange rate.
     */
    function setTokenRate(uint256 _tokenRate) onlyOwner {
        require (_tokenRate > 0);
        tokenRate = _tokenRate;
    }

    /**
     * Buy HQX. Tokens will be stored in contract until claim stage
     */
    function buy() payable inProgress whenNotPaused {
        uint256 payAmount = msg.value;
        uint256 returnAmount = 0;

        // calculate token amount to be transfered to investor
        uint256 tokensAmount = tokenRate.mul(payAmount);

        if (issuedTokensAmount + tokensAmount > maxTokensAmount) {
            tokensAmount = maxTokensAmount.sub(issuedTokensAmount);
            payAmount = tokensAmount.div(tokenRate);
            returnAmount = msg.value.sub(payAmount);
        }

        issuedTokensAmount = issuedTokensAmount.add(tokensAmount);
        require (issuedTokensAmount <= maxTokensAmount);

        storeTokens(msg.sender, tokensAmount);
        TokenBought(msg.sender, tokensAmount, payAmount);

        beneficiaryAddress.transfer(payAmount);

        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);
        }
    }

    /**
     * Add HQX payed by another crypto (BTC, LTC). Tokens will be stored in contract until claim stage
     */
    function add(address _receiver, uint256 _equivalentEthAmount) onlyOwner inProgress whenNotPaused {
        uint256 tokensAmount = tokenRate.mul(_equivalentEthAmount);
        issuedTokensAmount = issuedTokensAmount.add(tokensAmount);

        storeTokens(_receiver, tokensAmount);
        TokenAdded(_receiver, tokensAmount, _equivalentEthAmount);
    }

    /**
     * Add HQX by referral program. Tokens will be stored in contract until claim stage
     */
    function topUp(address _receiver, uint256 _equivalentEthAmount) onlyOwner whenNotPaused {
        uint256 tokensAmount = tokenRate.mul(_equivalentEthAmount);
        issuedTokensAmount = issuedTokensAmount.add(tokensAmount);

        storeTokens(_receiver, tokensAmount);
        TokenToppedUp(_receiver, tokensAmount, _equivalentEthAmount);
    }

    /**
     * Reduce bought HQX amount. Emergency use only
     */
    function sub(address _receiver, uint256 _equivalentEthAmount) onlyOwner whenNotPaused {
        uint256 tokensAmount = tokenRate.mul(_equivalentEthAmount);

        require (tokens[_receiver] >= tokensAmount);

        tokens[_receiver] = tokens[_receiver].sub(tokensAmount);
        issuedTokensAmount = issuedTokensAmount.sub(tokensAmount);

        TokenSubtracted(_receiver, tokensAmount, _equivalentEthAmount);
    }

    /**
     * Internal method for storing tokens in contract until claim stage
     */
    function storeTokens(address _receiver, uint256 _tokensAmount) internal whenNotPaused {
        if (tokens[_receiver] == 0) {
            tokenReceivers[receiversCount] = _receiver;
            receiversCount++;
            approved[_receiver] = false;
        }
        tokens[_receiver] = tokens[_receiver].add(_tokensAmount);
    }

    /**
     * Claim all bought HQX. Available tokens will be sent to transaction sender address if it is approved
     */
    function claim() whenNotPaused {
        claimFor(msg.sender);
    }

    /**
     * Claim all bought HQX for specific approved address
     */
    function claimOne(address _receiver) onlyOwner whenNotPaused {
        claimFor(_receiver);
    }

    /**
     * Claim all bought HQX for all approved addresses
     */
    function claimAll() onlyOwner whenNotPaused {
        for (uint32 i = 0; i < receiversCount; i++) {
            address receiver = tokenReceivers[i];
            if (approved[receiver] && tokens[receiver] > 0) {
                claimFor(receiver);
            }
        }
    }

    /**
     * Internal method for claiming tokens for specific approved address
     */
    function claimFor(address _receiver) internal whenNotPaused {
        require(approved[_receiver]);
        require(tokens[_receiver] > 0);

        uint256 tokensToSend = tokens[_receiver];
        tokens[_receiver] = 0;

        token.transferFrom(bankAddress, _receiver, tokensToSend);
        TokenSent(_receiver, tokensToSend);
    }

    function approve(address _receiver) onlyOwner whenNotPaused {
        approved[_receiver] = true;
    }

    /**
     * Finish Sale.
     */
    function finish() onlyOwner {
        require (issuedTokensAmount >= maxTokensAmount || now > endDate);
        require (!isFinished);
        isFinished = true;
        token.transfer(bankAddress, token.balanceOf(this));
    }

    function getReceiversCount() constant onlyOwner returns (uint32) {
        return receiversCount;
    }

    function getReceiver(uint32 i) constant onlyOwner returns (address) {
        return tokenReceivers[i];
    }

    /**
     * Buy HQX. Tokens will be stored in contract until claim stage
     */
    function() external payable {
        buy();
    }
}