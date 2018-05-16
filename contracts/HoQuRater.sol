pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorage.sol';
import './HoQuRaterI.sol';

contract HoQuRater is HoQuRaterI {
    using SafeMath for uint256;

    HoQuConfig public config;
    HoQuStorage public store;

    modifier onlyOwner() {
        require(config.isAllowed(msg.sender));
        _;
    }

    constructor(
        address configAddress,
        address storageAddress
    ) public {
        config = HoQuConfig(configAddress);
        store = HoQuStorage(storageAddress);
    }

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuConfig(configAddress);
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        store = HoQuStorage(storageAddress);
    }

    function processAddLead(bytes16 offerId, bytes16 trackerId, bytes16 affiliateId, uint256 price) public onlyOwner {
        // do nothing for now
    }

    function processTransactLead(bytes16 offerId, bytes16 trackerId, bytes16 affiliateId, uint256 price) public onlyOwner {
        // do nothing for now
    }
}