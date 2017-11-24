pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuPlatformConfig.sol';
import './HoQuToken.sol';

contract HoQuPlatform {
	using SafeMath for uint256;

	enum Status { NotExists, Created, Pending, Active, Declined }
    enum KycLevel { Tier0, Tier1, Tier2, Tier3, Tier4 }

    struct KycReport {
        uint createdAt;
        uint32 reportId;
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
		uint ownerId;
        address ownerAddress;
		string name;
		string dataUrl;
		Status status;
	}

	struct Offer {
        uint createdAt;
		uint companyId;
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

	struct Lead {
        uint createdAt;
        uint trackerId;
        uint ownerId;
        address beneficiaryAddress;
		uint offerId;
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

    mapping(uint32 => User) public users;
	mapping(uint32 => Company) public companies;
	mapping(uint32 => Offer) public offers;
    mapping(uint32 => Tracker) public trackers;
	mapping(uint32 => Lead) public leads;

    event UserRegistered(address indexed ownerAddress, uint32 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress);
    event UserPubKeyUpdated(address indexed ownerAddress);
    event UserKycReportAdded(address indexed ownerAddress, KycLevel kycLevel);
    event UserStatusChanged(address indexed ownerAddress, Status status);
    event CompanyRegistered(address indexed ownerAddress, uint32 id, string name);
    event CompanyStatusChanged(address indexed ownerAddress, Status status);
    event TrackerRegistered(address indexed ownerAddress, uint32 id, string name);
    event TrackerStatusChanged(address indexed ownerAddress, Status status);
    event OfferAdded(address indexed ownerAddress, uint32 id, string name);
    event OfferStatusChanged(address indexed ownerAddress, Status status);
    event LeadAdded(address indexed ownerAddress, uint32 id, uint256 price);
    event LeadStatusChanged(address indexed ownerAddress, Status status);

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

    function registerUser(uint32 id, string role, address ownerAddress, string pubKey) public onlyOwner returns (bool) {
        require (users[id].status == Status.NotExists);

        users[id] = User({
            createdAt: now,
            numOfAddresses: 1,
            role: role,
            kycLevel: KycLevel.Tier0,
            numOfKycReports: 0,
            pubKey: pubKey,
            status: Status.Created
        });
        users[id].addresses[0] = ownerAddress;

        UserRegistered(ownerAddress, id, role);

        return true;
    }

    function addUserAddress(uint32 id, address ownerAddress) public onlyOwner returns (bool) {
        require (users[id].status != Status.NotExists);

        users[id].addresses[users[id].numOfAddresses] = ownerAddress;
        users[id].numOfAddresses++;

        UserAddressAdded(users[id].addresses[0], ownerAddress);

        return true;
    }

    function updateUserPubKey(uint32 id, string pubKey) public onlyOwner returns (bool) {
        require (users[id].status != Status.NotExists);

        users[id].pubKey = pubKey;

        UserPubKeyUpdated(users[id].addresses[0]);

        return true;
    }

    function addUserKycReport(uint32 id, uint32 reportId, KycLevel kycLevel, string dataUrl) public onlyOwner returns (bool) {
        require (users[id].status != Status.NotExists);

        users[id].kycReports[users[id].numOfKycReports] = KycReport({
            createdAt: now,
            reportId: reportId,
            kycLevel: kycLevel,
            dataUrl: dataUrl
        });
        users[id].numOfKycReports++;
        users[id].kycLevel = kycLevel;

        UserKycReportAdded(users[id].addresses[0], kycLevel);

        return true;
    }

    function setUserStatus(uint32 id, Status status) public onlyOwner returns (bool) {
        require (users[id].status != Status.NotExists);

        users[id].status = status;

        UserStatusChanged(users[id].addresses[0], status);

        return true;
    }

    function getUserAddress(uint32 id, uint8 num) public constant returns (address) {
        require (users[id].status != Status.NotExists);

        return users[id].addresses[num];
    }

    function getUserKycReport(uint32 id, uint16 num) public constant returns (uint, uint32, KycLevel, string) {
        require (users[id].status != Status.NotExists);

        return (
            users[id].kycReports[num].createdAt,
            users[id].kycReports[num].reportId,
            users[id].kycReports[num].kycLevel,
            users[id].kycReports[num].dataUrl
        );
    }

    function registerCompany(uint32 id, uint32 ownerId, address ownerAddress, string name, string dataUrl) public onlyOwner returns (bool) {
        require (companies[id].status == Status.NotExists);
        require (users[ownerId].status != Status.NotExists);
        
        bool userAddressExists = false;
        for (uint8 i = 0; i < users[ownerId].numOfAddresses; i++) {
            if (users[ownerId].addresses[i] == ownerAddress) {
                userAddressExists = true;
            }
        }
        require (userAddressExists);
        
        companies[id] = Company({
            createdAt: now,
            ownerId: ownerId,
            ownerAddress: ownerAddress,
            name: name,
            dataUrl: dataUrl,
            status: Status.Created
        });

        CompanyRegistered(ownerAddress, id, name);

        return true;
    }
    
    function setCompanyStatus(uint32 id, Status status) public onlyOwner returns (bool) {
        require (companies[id].status != Status.NotExists);

        companies[id].status = status;

        CompanyStatusChanged(companies[id].ownerAddress, status);

        return true;
    }
    
    function registerTracker(uint32 id, address ownerAddress, string name, string dataUrl) public onlyOwner returns (bool) {
        require (trackers[id].status == Status.NotExists);

        trackers[id] = Tracker({
            createdAt: now,
            ownerAddress: ownerAddress,
            name: name,
            dataUrl: dataUrl,
            status: Status.Created
        });

        TrackerRegistered(ownerAddress, id, name);

        return true;
    }
    
    function setTrackerStatus(uint32 id, Status status) public onlyOwner returns (bool) {
        require (trackers[id].status != Status.NotExists);

        trackers[id].status = status;

        TrackerStatusChanged(trackers[id].ownerAddress, status);

        return true;
    }

    function addOffer(uint32 id, uint32 companyId, address payerAddress, string name, string dataUrl, uint256 cost) public onlyOwner returns (bool) {
        require (offers[id].status == Status.NotExists);
        require (companies[companyId].status != Status.NotExists);
        
        offers[id] = Offer({
            createdAt: now,
            companyId: companyId,
            payerAddress: payerAddress,
            name: name,
            dataUrl: dataUrl,
            cost: cost,
            status: Status.Created
        });

        OfferAdded(payerAddress, id, name);

        return true;
    }

    function setOfferStatus(uint32 id, Status status) public onlyOwner returns (bool) {
        require (offers[id].status != Status.NotExists);

        offers[id].status = status;

        OfferStatusChanged(offers[id].payerAddress, status);

        return true;
    }
    
    function addLead(uint32 id, uint32 ownerId, uint32 trackerId, uint32 offerId, address beneficiaryAddress, string meta, string dataUrl, uint256 price) public onlyOwner returns (bool) {
        require (leads[id].status == Status.NotExists);
        require (users[ownerId].status != Status.NotExists);
        require (trackers[trackerId].status != Status.NotExists);
        require (offers[offerId].status != Status.NotExists);

        leads[id] = Lead({
            createdAt: now,
            trackerId: trackerId,
            ownerId: ownerId,
            offerId: offerId,
            beneficiaryAddress: beneficiaryAddress,
            meta: meta,
            dataUrl: dataUrl,
            price: price,
            numOfIntermediaries: 0,
            status: Status.Created
        });

        LeadAdded(beneficiaryAddress, id, price);

        return true;
    }

    function addLeadIntermediary(uint32 id, address intermediaryAddress, uint32 percent) public onlyOwner returns (bool) {
        require (leads[id].status != Status.NotExists);

        leads[id].intermediaryAddresses[leads[id].numOfIntermediaries] = intermediaryAddress;
        leads[id].intermediaryPercents[leads[id].numOfIntermediaries] = percent;
        leads[id].numOfIntermediaries++;

        return true;
    }

    function setLeadStatus(uint32 id, Status status) public onlyOwner returns (bool) {
        require (leads[id].status != Status.NotExists);

        leads[id].status = status;

        LeadStatusChanged(leads[id].beneficiaryAddress, status);

        return true;
    }
}