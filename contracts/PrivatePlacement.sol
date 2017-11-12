pragma solidity ^0.4.11;

import './BaseCrowdsale.sol';

/**
 * @title PrivatePlacement
 * @dev HoQu.io Private Token Placement contract
 */
contract PrivatePlacement is BaseCrowdsale {

    // internal addresses for HoQu tokens allocation
    address public foundersAddress;
    address public supportAddress;
    address public bountyAddress;

    // initial amount distribution values
    uint256 public constant totalSupply = 888888000 ether;
    uint256 public constant initialFoundersAmount = 266666400 ether;
    uint256 public constant initialSupportAmount = 8888880 ether;
    uint256 public constant initialBountyAmount = 35555520 ether;

    // whether initial token allocations was performed or not
    bool allocatedInternalWallets = false;
    
    /**
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _foundersAddress founders address
    * @param _supportAddress support address
    * @param _bountyAddress bounty address
    * @param _beneficiaryAddress accepted ETH go to this address
    */
    function PrivatePlacement(
        address _bankAddress,
        address _foundersAddress,
        address _supportAddress,
        address _bountyAddress,
        address _beneficiaryAddress
    ) BaseCrowdsale(
        createToken(totalSupply),
        _bankAddress,
        _beneficiaryAddress,
        10000, /* rate HQX per 1 ETH (includes 100% private placement bonus) */
        100, /* min amount in ETH */
        23111088, /* cap in HQX */
        1506816000 /* end 10/01/2017 @ 12:00am (UTC) */
    ) {
        foundersAddress = _foundersAddress;
        supportAddress = _supportAddress;
        bountyAddress = _bountyAddress;
    }

    /*
     * @dev Perform initial token allocation between founders' addresses.
     * Is only executed once after presale contract deployment and is invoked manually.
     */
    function allocateInternalWallets() onlyOwner {
        require (!allocatedInternalWallets);

        allocatedInternalWallets = true;

        token.transfer(foundersAddress, initialFoundersAmount);
        token.transfer(supportAddress, initialSupportAmount);
        token.transfer(bountyAddress, initialBountyAmount);
    }
    
    /*
     * @dev HoQu Token factory.
     */
    function createToken(uint256 _totalSupply) internal returns (HoQuToken) {
        return new HoQuToken(_totalSupply);
    }
}