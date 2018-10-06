pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorageAccessor.sol';
import './HoQuAdCampaignI.sol';
import './HoQuRaterI.sol';
import './HoQuTransactor.sol';

contract HoQuAdCampaign is HoQuAdCampaignI, HoQuStorageAccessor {
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

    HoQuTransactor public transactor;
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
    event LeadAdded(address indexed beneficiaryAddress, bytes16 id, uint256 price, address senderAddress);
    event LeadTransacted(address indexed beneficiaryAddress, bytes16 id, uint256 amount, address senderAddress);
    event LeadStatusChanged(address indexed beneficiaryAddress, bytes16 id, HoQuStorageSchema.Status status);
    event TrackerAdded(address indexed ownerAddress, bytes16 id);

    modifier onlyOwnerOrTracker() {
        require(config.isAllowed(msg.sender) || trackers[msg.sender].length != 0);
        _;
    }

    constructor(
        address configAddress,
        address transactorAddress,
        address storageAddress,
        address raterAddress,
        bytes16 _adId,
        bytes16 _offerId,
        bytes16 _affiliateId,
        address _beneficiaryAddress,
        address _payerAddress
    ) HoQuStorageAccessor(
        configAddress,
        storageAddress
    ) public {
        transactor = HoQuTransactor(transactorAddress);
        rater = HoQuRaterI(raterAddress);
        adId = _adId;
        offerId = _offerId;
        affiliateId = _affiliateId;
        beneficiaryAddress = _beneficiaryAddress;
        payerAddress = _payerAddress;
    }

    function setTransactorAddress(address transactorAddress) public onlyOwner {
        transactor = HoQuTransactor(transactorAddress);
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
        HoQuStorageSchema.AdCampaign memory adCampaign = getAdCampaign(adId);
        require(adCampaign.status != HoQuStorageSchema.Status.NotExists);

        adCampaign.status = status;
        setAdCampaign(adId, adCampaign);

        status = _status;

        emit StatusChanged(payerAddress, _status);
    }

    function addLead(bytes16 id, bytes16 trackerId, string meta, string dataUrl, uint256 price) public onlyOwnerOrTracker {
        require(leads[id].status == HoQuStorageSchema.Status.NotExists);

        HoQuStorageSchema.Tracker memory tracker = getTracker(trackerId);
        require(tracker.status != HoQuStorageSchema.Status.NotExists);

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

        emit LeadAdded(beneficiaryAddress, id, price, msg.sender);
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

        transactor.withdraw(payerAddress, lead.price);
        transactor.send(config.commissionWallet(), commissionAmount);

        for (uint8 i = 0; i < lead.numOfIntermediaries; i++) {
            address receiver = lead.intermediaryAddresses[i];
            // Percent in micro-percents, i.e. 0.04% = 400 000 micro-percents
            uint32 percent = lead.intermediaryPercents[i];
            uint256 intermediaryAmount = lead.price.mul(percent).div(1e8);
            transactor.send(receiver, intermediaryAmount);

            ownerAmount = ownerAmount.sub(intermediaryAmount);
        }

        transactor.send(beneficiaryAddress, ownerAmount);

        rater.processTransactLead(offerId, lead.trackerId, affiliateId, lead.price);

        emit LeadTransacted(beneficiaryAddress, id, ownerAmount, msg.sender);
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