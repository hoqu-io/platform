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
        address ownerAddress;
        string name;
        string dataUrl;
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
        mapping (address => uint32) intermediaries;
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
}