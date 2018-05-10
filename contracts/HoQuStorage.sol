pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';

contract HoQuStorage is HoQuStorageSchema {
    using SafeMath for uint256;

    HoQuConfig public config;

    mapping (bytes16 => User) public users;
    mapping (bytes16 => Identification) public ids;
    mapping (bytes16 => Stats) public stats;
    mapping (bytes16 => Company) public companies;
    mapping (bytes16 => Network) public networks;
    mapping (bytes16 => Offer) public offers;
    mapping (bytes16 => Tracker) public trackers;
    mapping (bytes16 => AdCampaign) public adCampaigns;

    event UserRegistered(address indexed ownerAddress, bytes16 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress);
    event StatsChanged(address indexed ownerAddress, bytes16 id, uint256 rating);
    event IdentificationAdded(address indexed ownerAddress, bytes16 id, string name);
    event KycReportAdded(address indexed ownerAddress, KycLevel kycLevel);
    event CompanyRegistered(address indexed ownerAddress, bytes16 id, string name);
    event NetworkRegistered(address indexed ownerAddress, bytes16 id, string name);
    event TrackerRegistered(address indexed ownerAddress, bytes16 id, string name);
    event OfferAdded(address indexed ownerAddress, bytes16 id, string name);
    event AdCampaignAdded(address indexed ownerAddress, bytes16 id, address contractAddress);

    modifier onlyOwner() {
        require(config.isAllowed(msg.sender));
        _;
    }

    constructor(address configAddress) public {
        config = HoQuConfig(configAddress);
    }

}