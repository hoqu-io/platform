pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorage.sol';
import './HoQuAdCampaignI.sol';

contract HoQuPlatform {
    using SafeMath for uint256;

    HoQuConfig public config;
    HoQuStorage public store;

    event UserRegistered(address indexed ownerAddress, bytes16 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress);
    event UserPubKeyUpdated(address indexed ownerAddress);
    event UserStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event IdentificationAdded(address indexed ownerAddress, bytes16 id, string name);
    event KycReportAdded(address indexed ownerAddress, HoQuStorageSchema.KycLevel kycLevel);
    event CompanyRegistered(address indexed ownerAddress, bytes16 id, string name);
    event CompanyStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event NetworkRegistered(address indexed ownerAddress, bytes16 id, string name);
    event NetworkStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event TrackerRegistered(address indexed ownerAddress, bytes16 id, string name);
    event TrackerStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event OfferAdded(address indexed ownerAddress, bytes16 id, string name);
    event OfferStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event AdCampaignAdded(address indexed ownerAddress, bytes16 id, address contractAddress);
    event AdCampaignStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event LeadAdded(address indexed contractAddress, bytes16 adCampaignId, bytes16 id);
    event LeadTransacted(address indexed contractAddress, bytes16 adCampaignId, bytes16 id);

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

}