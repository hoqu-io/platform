pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuPlatformConfig.sol';
import './HoQuToken.sol';

contract HoQuPlatform {
    using SafeMath for uint256;

    enum Status {NotExists, Created, Pending, Active, Done, Declined}
    enum KycLevel {Tier0, Tier1, Tier2, Tier3, Tier4}

    struct KycReport {
        uint createdAt;
        string meta;
        KycLevel kycLevel;
        string dataUrl;
    }

    struct User {
        uint createdAt;
        mapping (uint8 => address) addresses;
        uint8 numOfAddresses;
        string role;
        KycLevel kycLevel;
        mapping (uint16 => KycReport) kycReports;
        uint16 numOfKycReports;
        string pubKey;
        Status status;
    }

    struct Company {
        uint createdAt;
        bytes16 ownerId;
        address ownerAddress;
        string name;
        string dataUrl;
        Status status;
    }

    struct Offer {
        uint createdAt;
        bytes16 companyId;
        address payerAddress;
        string name;
        string dataUrl;
        uint256 cost;
        Status status;
    }

    struct Tracker {
        uint createdAt;
        address ownerAddress;
        string name;
        string dataUrl;
        Status status;
    }

    struct Ad {
        uint createdAt;
        bytes16 ownerId;
        address beneficiaryAddress;
        bytes16 offerId;
        Status status;
    }

    struct Lead {
        uint createdAt;
        bytes16 trackerId;
        bytes16 adId;
        string dataUrl;
        string meta;
        uint256 price;
        mapping (uint8 => address) intermediaryAddresses;
        mapping (uint8 => uint32) intermediaryPercents;
        uint8 numOfIntermediaries;
        Status status;
    }

    HoQuPlatformConfig public config;
    HoQuToken public token;

    mapping (bytes16 => User) public users;
    mapping (bytes16 => Company) public companies;
    mapping (bytes16 => Offer) public offers;
    mapping (bytes16 => Tracker) public trackers;
    mapping (bytes16 => Ad) public ads;
    mapping (bytes16 => Lead) public leads;

    event UserRegistered(address indexed ownerAddress, bytes16 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress);
    event UserPubKeyUpdated(address indexed ownerAddress);
    event UserKycReportAdded(address indexed ownerAddress, KycLevel kycLevel);
    event UserStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event CompanyRegistered(address indexed ownerAddress, bytes16 id, string name);
    event CompanyStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event TrackerRegistered(address indexed ownerAddress, bytes16 id, string name);
    event TrackerStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event OfferAdded(address indexed ownerAddress, bytes16 id, string name);
    event OfferStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event AdAdded(address indexed ownerAddress, bytes16 id);
    event AdStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event LeadAdded(address indexed ownerAddress, bytes16 id, uint256 price);
    event LeadStatusChanged(address indexed ownerAddress, bytes16 id, Status status);
    event LeadSold(address indexed ownerAddress, bytes16 id, uint256 ownerAmount);

    modifier onlyOwner() {
        require(msg.sender == config.systemOwner());
        _;
    }

    function HoQuPlatform(
        address configAddress,
        address tokenAddress
    ) public {
        config = HoQuPlatformConfig(configAddress);
        token = HoQuToken(tokenAddress);
    }

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuPlatformConfig(configAddress);
    }

    function registerUser(bytes16 id, string role, address ownerAddress, string pubKey) public onlyOwner returns (bool) {
        require(users[id].status == Status.NotExists);

        users[id] = User({
            createdAt : now,
            numOfAddresses : 1,
            role : role,
            kycLevel : KycLevel.Tier0,
            numOfKycReports : 0,
            pubKey : pubKey,
            status : Status.Created
        });
        users[id].addresses[0] = ownerAddress;

        UserRegistered(ownerAddress, id, role);

        return true;
    }

    function addUserAddress(bytes16 id, address ownerAddress) public onlyOwner returns (bool) {
        require(users[id].status != Status.NotExists);

        users[id].addresses[users[id].numOfAddresses] = ownerAddress;
        users[id].numOfAddresses++;

        UserAddressAdded(users[id].addresses[0], ownerAddress);

        return true;
    }

    function updateUserPubKey(bytes16 id, string pubKey) public onlyOwner returns (bool) {
        require(users[id].status != Status.NotExists);

        users[id].pubKey = pubKey;

        UserPubKeyUpdated(users[id].addresses[0]);

        return true;
    }

    function addUserKycReport(bytes16 id, string meta, KycLevel kycLevel, string dataUrl) public onlyOwner returns (bool) {
        require(users[id].status != Status.NotExists);

        users[id].kycReports[users[id].numOfKycReports] = KycReport({
            createdAt : now,
            meta : meta,
            kycLevel : kycLevel,
            dataUrl : dataUrl
        });
        users[id].numOfKycReports++;
        users[id].kycLevel = kycLevel;

        UserKycReportAdded(users[id].addresses[0], kycLevel);

        return true;
    }

    function setUserStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(users[id].status != Status.NotExists);

        users[id].status = status;

        UserStatusChanged(users[id].addresses[0], id, status);

        return true;
    }

    function getUserAddress(bytes16 id, uint8 num) public constant returns (address) {
        require(users[id].status != Status.NotExists);

        return users[id].addresses[num];
    }

    function getUserKycReport(bytes16 id, uint16 num) public constant returns (uint, string, KycLevel, string) {
        require(users[id].status != Status.NotExists);

        return (
        users[id].kycReports[num].createdAt,
        users[id].kycReports[num].meta,
        users[id].kycReports[num].kycLevel,
        users[id].kycReports[num].dataUrl
        );
    }

    function registerCompany(bytes16 id, bytes16 ownerId, address ownerAddress, string name, string dataUrl) public onlyOwner returns (bool) {
        require(companies[id].status == Status.NotExists);
        require(users[ownerId].status != Status.NotExists);

        bool userAddressExists = false;
        for (uint8 i = 0; i < users[ownerId].numOfAddresses; i++) {
            if (users[ownerId].addresses[i] == ownerAddress) {
                userAddressExists = true;
            }
        }
        require(userAddressExists);

        companies[id] = Company({
            createdAt : now,
            ownerId : ownerId,
            ownerAddress : ownerAddress,
            name : name,
            dataUrl : dataUrl,
            status : Status.Created
        });

        CompanyRegistered(ownerAddress, id, name);

        return true;
    }

    function setCompanyStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(companies[id].status != Status.NotExists);

        companies[id].status = status;

        CompanyStatusChanged(companies[id].ownerAddress, id, status);

        return true;
    }

    function registerTracker(bytes16 id, address ownerAddress, string name, string dataUrl) public onlyOwner returns (bool) {
        require(trackers[id].status == Status.NotExists);

        trackers[id] = Tracker({
            createdAt : now,
            ownerAddress : ownerAddress,
            name : name,
            dataUrl : dataUrl,
            status : Status.Created
        });

        TrackerRegistered(ownerAddress, id, name);

        return true;
    }

    function setTrackerStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(trackers[id].status != Status.NotExists);

        trackers[id].status = status;

        TrackerStatusChanged(trackers[id].ownerAddress, id, status);

        return true;
    }

    function addOffer(bytes16 id, bytes16 companyId, address payerAddress, string name, string dataUrl, uint256 cost) public onlyOwner returns (bool) {
        require(offers[id].status == Status.NotExists);
        require(companies[companyId].status != Status.NotExists);

        offers[id] = Offer({
            createdAt : now,
            companyId : companyId,
            payerAddress : payerAddress,
            name : name,
            dataUrl : dataUrl,
            cost : cost,
            status : Status.Created
        });

        OfferAdded(payerAddress, id, name);

        return true;
    }

    function setOfferStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(offers[id].status != Status.NotExists);

        offers[id].status = status;

        OfferStatusChanged(offers[id].payerAddress, id, status);

        return true;
    }

    function addAd(bytes16 id, bytes16 ownerId, bytes16 offerId, address beneficiaryAddress) public onlyOwner returns (bool) {
        require(ads[id].status == Status.NotExists);
        require(users[ownerId].status != Status.NotExists);
        require(offers[offerId].status != Status.NotExists);

        ads[id] = Ad({
            createdAt : now,
            ownerId : ownerId,
            offerId : offerId,
            beneficiaryAddress : beneficiaryAddress,
            status : Status.Created
        });

        AdAdded(beneficiaryAddress, id);

        return true;
    }

    function setAdStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(ads[id].status != Status.NotExists);

        ads[id].status = status;

        AdStatusChanged(ads[id].beneficiaryAddress, id, status);

        return true;
    }

    function addLead(bytes16 id, bytes16 adId, bytes16 trackerId, string meta, string dataUrl, uint256 price) public onlyOwner returns (bool) {
        require(leads[id].status == Status.NotExists);
        require(ads[adId].status != Status.NotExists);
        require(trackers[trackerId].status != Status.NotExists);

        leads[id] = Lead({
            createdAt : now,
            trackerId : trackerId,
            adId : adId,
            meta : meta,
            dataUrl : dataUrl,
            price : price,
            numOfIntermediaries : 0,
            status : Status.Created
        });

        LeadAdded(ads[adId].beneficiaryAddress, id, price);

        return true;
    }

    function addLeadIntermediary(bytes16 id, address intermediaryAddress, uint32 percent) public onlyOwner returns (bool) {
        require(leads[id].status != Status.NotExists);

        leads[id].intermediaryAddresses[leads[id].numOfIntermediaries] = intermediaryAddress;
        leads[id].intermediaryPercents[leads[id].numOfIntermediaries] = percent;
        leads[id].numOfIntermediaries++;

        return true;
    }

    function sellLead(bytes16 id) public onlyOwner returns (bool) {
        require(leads[id].status != Status.Done && leads[id].status != Status.Declined);
        require(leads[id].price > 0);

        leads[id].status = Status.Done;

        Lead lead = leads[id];
        Ad ad = ads[lead.adId];
        Offer offer = offers[ad.offerId];

        uint256 commissionAmount = lead.price.mul(config.commission()).div(1 ether);
        uint256 ownerAmount = lead.price.sub(commissionAmount);

        token.transferFrom(offer.payerAddress, this, lead.price);
        token.transfer(config.commissionWallet(), commissionAmount);

        for (uint8 i = 0; i < lead.numOfIntermediaries; i++) {
            address receiver = lead.intermediaryAddresses[i];
            // Percent in micro-percents, i.e. 0.04% = 400 000 micro-percents
            uint32 percent = lead.intermediaryPercents[i];
            uint256 intermediaryAmount = lead.price.mul(percent).div(1e8);
            token.transfer(receiver, intermediaryAmount);

            ownerAmount = ownerAmount.sub(intermediaryAmount);
        }

        token.transfer(ad.beneficiaryAddress, ownerAmount);

        LeadSold(ad.beneficiaryAddress, id, ownerAmount);

        return true;
    }

    function setLeadStatus(bytes16 id, Status status) public onlyOwner returns (bool) {
        require(leads[id].status != Status.NotExists);

        leads[id].status = status;

        LeadStatusChanged(ads[leads[id].adId].beneficiaryAddress, id, status);

        return true;
    }

    function getLeadIntermediaryAddress(bytes16 id, uint8 num) public constant returns (address) {
        require(leads[id].status != Status.NotExists);

        return leads[id].intermediaryAddresses[num];
    }

    function getLeadIntermediaryPercent(bytes16 id, uint8 num) public constant returns (uint32) {
        require(leads[id].status != Status.NotExists);

        return leads[id].intermediaryPercents[num];
    }
}