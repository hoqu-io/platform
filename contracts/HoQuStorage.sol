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

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuConfig(configAddress);
    }

    function setUser(bytes16 id, string role, address ownerAddress, KycLevel kycLevel, string pubKey, Status status) public onlyOwner {
        if (users[id].status == Status.NotExists) {
            users[id] = User({
                createdAt : now,
                numOfAddresses : 1,
                role : role,
                kycLevel : KycLevel.Tier1,
                pubKey : pubKey,
                status : Status.Created
            });
            users[id].addresses[0] = ownerAddress;

            emit UserRegistered(ownerAddress, id, role);
        } else {
            if (bytes(role).length != 0) {
                users[id].role = role;
            }
            if (kycLevel != KycLevel.Undefined) {
                users[id].kycLevel = kycLevel;
            }
            if (bytes(pubKey).length != 0) {
                users[id].pubKey = pubKey;
            }
            if (status != Status.NotExists) {
                users[id].status = status;
            }
        }
    }

    function addUserAddress(bytes16 id, address ownerAddress) public onlyOwner {
        require(users[id].status != Status.NotExists);

        users[id].addresses[users[id].numOfAddresses] = ownerAddress;
        users[id].numOfAddresses++;

        emit UserAddressAdded(users[id].addresses[0], ownerAddress);
    }

    function getUserAddress(bytes16 id, uint8 num) public constant returns (address) {
        require(users[id].status != Status.NotExists);

        return users[id].addresses[num];
    }

}