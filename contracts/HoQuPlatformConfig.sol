pragma solidity ^0.4.17;

contract HoQuPlatformConfig {
    // todo: implement multiple owners with voting (in different contract)
    address public systemOwner;
    address public commissionWallet;

    function HoQuPlatformConfig(address _systemOwner, address _commissionWallet) public {
        systemOwner = _systemOwner;
        commissionWallet = _commissionWallet;
    }
}