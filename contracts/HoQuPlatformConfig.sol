pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract HoQuPlatformConfig is Ownable {

    address public systemOwner;
    address public commissionWallet;

    // HoQu platform commission in ether
    uint256 public commission = 0.005 ether;

    event SystemOwnerChanged(address indexed previousOwner, address newOwner);
    event CommissionWalletChanged(address indexed changedBy, address commissionWallet);
    event CommissionChanged(address indexed changedBy, uint256 commission);

    modifier onlyOwners() {
        require(msg.sender == owner || msg.sender == systemOwner);
        _;
    }

    function HoQuPlatformConfig(
        address _systemOwner,
        address _commissionWallet
    ) public {
        systemOwner = _systemOwner;
        commissionWallet = _commissionWallet;
    }

    function setSystemOwner(address _systemOwner) public onlyOwners {
        require(_systemOwner != address(0));
        SystemOwnerChanged(systemOwner, _systemOwner);
        systemOwner = _systemOwner;
    }

    function setCommissionWallet(address _commissionWallet) public onlyOwners {
        require(_commissionWallet != address(0));
        CommissionWalletChanged(msg.sender, _commissionWallet);
        commissionWallet = _commissionWallet;
    }

    function setCommission(uint256 _commission) public onlyOwners {
        require(_commission > 0);
        CommissionChanged(msg.sender, _commission);
        commission = _commission;
    }
}