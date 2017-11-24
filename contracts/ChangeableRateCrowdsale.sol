pragma solidity ^0.4.11;

import './ClaimableCrowdsale.sol';

/**
 * @title ChangeableRateCrowdsale
 * @dev HoQu.io Main Sale stage
 */
contract ChangeableRateCrowdsale is ClaimableCrowdsale {

    struct RateBoundary {
        uint256 amount;
        uint256 rate;
    }

    mapping (uint => RateBoundary) public rateBoundaries;
    uint public currentBoundary = 0;
    uint public numOfBoundaries = 0;
    uint256 public nextBoundaryAmount;

    /**
    * @param _tokenAddress address of a HQX token contract
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _beneficiaryAddress accepted ETH go to this address
    * @param _tokenRate rate HQX per 1 ETH
    * @param _minBuyableAmount min ETH per each buy action (in ETH wei)
    * @param _maxTokensAmount ICO HQX capacity (in HQX wei)
    * @param _endDate the date when ICO will expire
    */
    function ChangeableRateCrowdsale(
        address _tokenAddress,
        address _bankAddress,
        address _beneficiaryAddress,
        uint256 _tokenRate,
        uint256 _minBuyableAmount,
        uint256 _maxTokensAmount,
        uint256 _endDate
    ) ClaimableCrowdsale(
        _tokenAddress,
        _bankAddress,
        _beneficiaryAddress,
        _tokenRate,
        _minBuyableAmount,
        _maxTokensAmount,
        _endDate
    ) {
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 13777764 ether,
            rate : 6000
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 27555528 ether,
            rate : 5750
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 41333292 ether,
            rate : 5650
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 55111056 ether,
            rate : 5550
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 68888820 ether,
            rate : 5450
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 82666584 ether,
            rate : 5350
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 96444348 ether,
            rate : 5250
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 110222112 ether,
            rate : 5150
        });
        rateBoundaries[numOfBoundaries++] = RateBoundary({
            amount : 137777640 ether,
            rate : 5000
        });
        nextBoundaryAmount = rateBoundaries[currentBoundary].amount;
    }

    /**
     * Internal method to change rate if boundary is hit
     */
    function touchRate() internal {
        if (issuedTokensAmount >= nextBoundaryAmount) {
            currentBoundary++;
            if (currentBoundary >= numOfBoundaries) {
                nextBoundaryAmount = maxTokensAmount;
            }
            else {
                nextBoundaryAmount = rateBoundaries[currentBoundary].amount;
                tokenRate = rateBoundaries[currentBoundary].rate;
            }
        }
    }

    /**
     * Inherited internal method for storing tokens in contract until claim stage
     */
    function storeTokens(address _receiver, uint256 _tokensAmount) internal whenNotPaused {
        ClaimableCrowdsale.storeTokens(_receiver, _tokensAmount);
        touchRate();
    }
}