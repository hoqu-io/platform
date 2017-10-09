pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

/**
 * @title HoQuToken
 * @dev HoQu.io token contract.
 */
contract HoQuToken is StandardToken, Pausable {
    
    string public constant name = "HOQU Token";
    string public constant symbol = "HQX";
    uint32 public constant decimals = 18;
    
    /**
     * @dev Give all tokens to msg.sender.
     */
    function HoQuToken(uint _totalSupply) {
        require (_totalSupply > 0);
        totalSupply = balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint _value) whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}