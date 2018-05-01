pragma solidity ^0.4.23;

import "./zeppelin/ownership/Ownable.sol";
import './zeppelin/math/SafeMath.sol';

contract HoQuConfig is Ownable {
    using SafeMath for uint256;

    address public commissionWallet;

    // HoQu platform commission in ether
    uint256 public commission = 0.005 ether;

    // a list of system owners' addresses
    mapping (uint16 => address) public owners;
    // a number of owners
    uint16 public ownersCount;

    event CommissionWalletChanged(address indexed changedBy, address commissionWallet);
    event CommissionChanged(address indexed changedBy, uint256 commission);
    event SystemOwnerAdded(address indexed newOwner);
    event SystemOwnerChanged(address indexed previousOwner, address newOwner);
    event SystemOwnerDeleted(address indexed deletedOwner);

    modifier onlyOwners() {
        require(msg.sender == owner || isAllowed(msg.sender));
        _;
    }

    constructor(
        address _commissionWallet
    ) public {
        commissionWallet = _commissionWallet;
    }

}