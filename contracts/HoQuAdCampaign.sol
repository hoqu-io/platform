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

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuConfig(configAddress);
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        token = ERC20(tokenAddress);
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        store = HoQuStorage(storageAddress);
    }

    function setRaterAddress(address raterAddress) public onlyOwner {
        rater = HoQuRaterI(raterAddress);
    }

    function setBeneficiaryAddress(address _beneficiaryAddress) public onlyOwner {
        emit BeneficiaryAddressChanged(beneficiaryAddress, _beneficiaryAddress);

        beneficiaryAddress = _beneficiaryAddress;
    }

    function setPayerAddress(address _payerAddress) public onlyOwner {
        emit PayerAddressChanged(payerAddress, _payerAddress);

        payerAddress = _payerAddress;
    }

    function addTracker(address ownerAddress, bytes16 id) public onlyOwner {
        trackers[ownerAddress] = id;

        emit TrackerAdded(ownerAddress, id);
    }

    function setStatus(HoQuStorageSchema.Status _status) public onlyOwner {
        HoQuStorageSchema.Status _storeStatus;
        (, _storeStatus) = store.adCampaigns(adId);
        require(_storeStatus != HoQuStorageSchema.Status.NotExists);

        store.setAdCampaign(adId, bytes16(""), bytes16(""), address(0), _status);

        status = _status;

        emit StatusChanged(payerAddress, _status);
    }

    function addLead(bytes16 id, bytes16 trackerId, string meta, string dataUrl, uint256 price) public onlyOwnerOrTracker {
        require(leads[id].status == HoQuStorageSchema.Status.NotExists);

        HoQuStorageSchema.Status _trackerStatus;
        (, _trackerStatus) = store.trackers(trackerId);
        require(_trackerStatus != HoQuStorageSchema.Status.NotExists);

        leads[id] = Lead({
            createdAt : now,
            trackerId : trackerId,
            meta : meta,
            dataUrl : dataUrl,
            price : price,
            numOfIntermediaries : 0,
            status : HoQuStorageSchema.Status.Created
        });

        rater.processAddLead(offerId, trackerId, affiliateId, price);

        emit LeadAdded(beneficiaryAddress, id, price);
    }

    function addLeadIntermediary(bytes16 id, address intermediaryAddress, uint32 percent) public onlyOwnerOrTracker {
        require(leads[id].status != HoQuStorageSchema.Status.NotExists);

        leads[id].intermediaryAddresses[leads[id].numOfIntermediaries] = intermediaryAddress;
        leads[id].intermediaryPercents[leads[id].numOfIntermediaries] = percent;
        leads[id].numOfIntermediaries++;
    }

    function transactLead(bytes16 id) public onlyOwnerOrTracker {
        require(leads[id].status != HoQuStorageSchema.Status.Done && leads[id].status != HoQuStorageSchema.Status.Declined);
        require(leads[id].price > 0);

        leads[id].status = HoQuStorageSchema.Status.Done;

        Lead storage lead = leads[id];

        uint256 commissionAmount = lead.price.mul(config.commission()).div(1 ether);
        uint256 ownerAmount = lead.price.sub(commissionAmount);

        token.transferFrom(payerAddress, this, lead.price);
        token.transfer(config.commissionWallet(), commissionAmount);

        for (uint8 i = 0; i < lead.numOfIntermediaries; i++) {
            address receiver = lead.intermediaryAddresses[i];
            // Percent in micro-percents, i.e. 0.04% = 400 000 micro-percents
            uint32 percent = lead.intermediaryPercents[i];
            uint256 intermediaryAmount = lead.price.mul(percent).div(1e8);
            token.transfer(receiver, intermediaryAmount);

            ownerAmount = ownerAmount.sub(intermediaryAmount);
        }

        token.transfer(beneficiaryAddress, ownerAmount);

        rater.processTransactLead(offerId, lead.trackerId, affiliateId, lead.price);

        emit LeadTransacted(beneficiaryAddress, id, ownerAmount);
        emit LeadStatusChanged(beneficiaryAddress, id, HoQuStorageSchema.Status.Done);
    }

    function setLeadStatus(bytes16 id, HoQuStorageSchema.Status _status) public onlyOwnerOrTracker {
        require(leads[id].status != HoQuStorageSchema.Status.NotExists);

        leads[id].status = _status;

        emit LeadStatusChanged(beneficiaryAddress, id, _status);
    }

    function getLeadIntermediaryAddress(bytes16 id, uint8 num) public constant returns (address) {
        require(leads[id].status != HoQuStorageSchema.Status.NotExists);

        return leads[id].intermediaryAddresses[num];
    }

    function getLeadIntermediaryPercent(bytes16 id, uint8 num) public constant returns (uint32) {
        require(leads[id].status != HoQuStorageSchema.Status.NotExists);

        return leads[id].intermediaryPercents[num];
    }
}