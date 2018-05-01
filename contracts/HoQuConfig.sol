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

    function setCommissionWallet(address _commissionWallet) public onlyOwners {
        require(_commissionWallet != address(0));
        emit CommissionWalletChanged(msg.sender, _commissionWallet);
        commissionWallet = _commissionWallet;
    }

    function setCommission(uint256 _commission) public onlyOwners {
        require(_commission > 0);
        emit CommissionChanged(msg.sender, _commission);
        commission = _commission;
    }

    /**
    * Add new owner to the list of system owners
    *
    * @param _owner ethereum address of the owner
    */
    function addOwner(address _owner) public onlyOwners {
        owners[ownersCount] = _owner;
        ownersCount++;
        emit SystemOwnerAdded(_owner);
    }

}