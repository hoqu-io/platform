pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorage.sol';
import './HoQuAdCampaignI.sol';
import './HoQuRaterI.sol';

contract HoQuAdCampaign is HoQuAdCampaignI {
    using SafeMath for uint256;

    struct Lead {
        uint createdAt;
        bytes16 trackerId;
        string dataUrl;
        string meta;
        uint256 price;
        mapping (uint8 => address) intermediaryAddresses;
        mapping (uint8 => uint32) intermediaryPercents;
        uint8 numOfIntermediaries;
        HoQuStorageSchema.Status status;
    }

    HoQuConfig public config;
    ERC20 public token;
    HoQuStorage public store;
    HoQuRaterI public rater;

    bytes16 public adId;
    bytes16 public offerId;
    bytes16 public affiliateId;
    address public beneficiaryAddress;
    address public payerAddress;
    HoQuStorageSchema.Status public status;

    mapping (bytes16 => Lead) public leads;
    mapping (address => bytes16) public trackers;

    event StatusChanged(address indexed payerAddress, HoQuStorageSchema.Status newStatus);
    event BeneficiaryAddressChanged(address indexed beneficiaryAddress, address indexed newBeneficiaryAddress);
    event PayerAddressChanged(address indexed payerAddress, address indexed newPayerAddress);
    event LeadAdded(address indexed beneficiaryAddress, bytes16 id, uint256 price);
    event LeadTransacted(address indexed beneficiaryAddress, bytes16 id, uint256 amount);
    event LeadStatusChanged(address indexed beneficiaryAddress, bytes16 id, HoQuStorageSchema.Status status);
    event TrackerAdded(address indexed ownerAddress, bytes16 id);

    modifier onlyOwner() {
        require(config.isAllowed(msg.sender));
        _;
    }

    modifier onlyOwnerOrTracker() {
        require(config.isAllowed(msg.sender) || trackers[msg.sender].length != 0);
        _;
    }

    constructor(
        address configAddress,
        address tokenAddress,
        address storageAddress,
        address raterAddress,
        bytes16 _adId,
        bytes16 _offerId,
        bytes16 _affiliateId,
        address _beneficiaryAddress,
        address _payerAddress
    ) public {
        config = HoQuConfig(configAddress);
        token = ERC20(tokenAddress);
        store = HoQuStorage(storageAddress);
        rater = HoQuRaterI(raterAddress);
        adId = _adId;
        offerId = _offerId;
        affiliateId = _affiliateId;
        beneficiaryAddress = _beneficiaryAddress;
        payerAddress = _payerAddress;
    }

}