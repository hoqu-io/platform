pragma solidity ^0.4.16;


import './zeppelin-solidity/contracts/math/SafeMath.sol';
import './zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './HoQuToken.sol';


/**
 * @title HoQuClaim
 * @title HoQu.io claim stage contract.
 */
contract HoQuClaim is Pausable {
    using SafeMath for uint256;

    // bank with all claimable tokens
    address public bankAddress;

    // token instance
    HoQuToken public token;

    mapping (address => uint256) internal claimed;

    /**
    * Events for token purchase logging
    */
    event TokenSent(address indexed _receiver, uint256 _tokens);

    event AlreadyClaimed(address indexed _receiver, uint256 _tokens);

    /**
    * @param _tokenAddress address of a HQX token contract
    * @param _bankAddress bank address with HQX tokens
    */
    function HoQuClaim(address _tokenAddress, address _bankAddress) {
        token = HoQuToken(_tokenAddress);
        bankAddress = _bankAddress;
    }

    /**
     * Claim HQX for a particular address
     */
    function claimOne(address _receiver, uint256 _tokens) onlyOwner whenNotPaused {
        claimFor(_receiver, _tokens);
    }

    /**
     * Claim HQX for a list of addresses
     */
    function claimMany(address[] _receiver, uint256[] _tokens) onlyOwner whenNotPaused {
        require(_receiver.length == _tokens.length);

        for (uint i = 0; i < _receiver.length; i++) {
            if (claimed[_receiver[i]] == 0) {
                claimFor(_receiver[i], _tokens[i]);
            }
            else {
                AlreadyClaimed(_receiver[i], _tokens[i]);
            }
        }
    }

    /**
     * Internal method for claiming tokens for a particular address
     */
    function claimFor(address _receiver, uint256 _tokens) internal onlyOwner whenNotPaused {
        claimed[_receiver] = claimed[_receiver].add(_tokens);

        token.transferFrom(bankAddress, _receiver, _tokens);
        TokenSent(_receiver, _tokens);
    }
}