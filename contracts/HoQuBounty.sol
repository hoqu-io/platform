pragma solidity ^0.4.11;


import './ClaimableCrowdsale.sol';


/**
 * @title HoQuBounty
 * @dev HoQu.io Bounty
 */
contract HoQuBounty is ClaimableCrowdsale {

    event TokenAddedByBounty(address indexed _receiver, uint256 _tokens);

    /**
    * @param _tokenAddress address of a HQX token contract
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _beneficiaryAddress accepted ETH go to this address
    */
    function HoQuBounty(
        address _tokenAddress,
        address _bankAddress,
        address _beneficiaryAddress
    ) ClaimableCrowdsale(
        _tokenAddress,
        _bankAddress,
        _beneficiaryAddress,
        6000,
        10000000000000000,
        137777640000000000000000000,
        1546041600
    ) {

    }

    /**
     * Add HQX by bounty program. Tokens will be stored in contract until claim stage
     */
    function addByBounty(address _receiver, uint256 _tokensAmount) onlyOwner whenNotPaused {
        issuedTokensAmount = issuedTokensAmount.add(_tokensAmount);

        storeTokens(_receiver, _tokensAmount);
        TokenAddedByBounty(_receiver, _tokensAmount);
    }

    /**
     * Approve all addresses
     */
    function approveAll() onlyOwner whenNotPaused {
        for (uint32 i = 0; i < receiversCount; i++) {
            address receiver = tokenReceivers[i];
            approve(receiver);
        }
    }
}