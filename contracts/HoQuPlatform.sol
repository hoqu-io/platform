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

    function setConfigAddress(address configAddress) public onlyOwner {
        config = HoQuConfig(configAddress);
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        store = HoQuStorage(storageAddress);
    }

    function registerUser(bytes16 id, string role, address ownerAddress, string pubKey) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.users(id);
        require(_status == HoQuStorageSchema.Status.NotExists);

        store.setUser(id, role, ownerAddress, HoQuStorageSchema.KycLevel.Tier1, pubKey, HoQuStorageSchema.Status.Created);

        emit UserRegistered(ownerAddress, id, role);
    }

    function addUserAddress(bytes16 id, address ownerAddress) public onlyOwner {
        store.addUserAddress(id, ownerAddress);

        address primaryAddress = store.getUserAddress(id, 0);
        emit UserAddressAdded(primaryAddress, ownerAddress);
    }

    function updateUserPubKey(bytes16 id, string pubKey) public onlyOwner {
        address primaryAddress = store.getUserAddress(id, 0);

        store.setUser(id, "", address(0), HoQuStorageSchema.KycLevel.Undefined, pubKey, HoQuStorageSchema.Status.NotExists);

        emit UserPubKeyUpdated(primaryAddress);
    }

    function setUserStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        address primaryAddress = store.getUserAddress(id, 0);

        store.setUser(id, "", address(0), HoQuStorageSchema.KycLevel.Undefined, "", status);

        emit UserStatusChanged(primaryAddress, id, status);
    }

    function getUserAddress(bytes16 id, uint8 num) public constant returns (address) {
        return store.getUserAddress(id, num);
    }

    function addIdentification(bytes16 id, bytes16 userId, string idType, string name, bytes16 companyId) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.ids(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(userId, 0);

        store.setIdentification(id, userId, idType, name, companyId, HoQuStorageSchema.Status.Created);

        emit IdentificationAdded(primaryAddress, id, name);
    }

    function addKycReport(bytes16 id, string meta, HoQuStorageSchema.KycLevel kycLevel, string dataUrl) public onlyOwner {
        bytes16 _userId;
        (_userId,) = store.ids(id);
        address primaryAddress = store.getUserAddress(_userId, 0);

        store.addKycReport(id, meta, kycLevel, dataUrl);

        emit KycReportAdded(primaryAddress, kycLevel);
    }

    function getKycReport(bytes16 id, uint16 num) public constant returns (uint, string, HoQuStorageSchema.KycLevel, string) {
        return store.getKycReport(id, num);
    }

    function registerCompany(bytes16 id, bytes16 ownerId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.companies(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(ownerId, 0);

        store.setCompany(id, ownerId, name, dataUrl, HoQuStorageSchema.Status.Created);
        emit CompanyRegistered(primaryAddress, id, name);
    }

    function setCompanyStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.companies(id);
        require(_status != HoQuStorageSchema.Status.NotExists);

        bytes16 _ownerId;
        (_ownerId, ) = store.companies(id);
        address primaryAddress = store.getUserAddress(_ownerId, 0);

        store.setCompany(id, bytes16(""), "", "", status);

        emit CompanyStatusChanged(primaryAddress, id, status);
    }

    function registerNetwork(bytes16 id, bytes16 ownerId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.networks(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(ownerId, 0);

        store.setNetwork(id, ownerId, name, dataUrl, HoQuStorageSchema.Status.Created);
        emit NetworkRegistered(primaryAddress, id, name);
    }

    function setNetworkStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.networks(id);
        require(_status != HoQuStorageSchema.Status.NotExists);

        bytes16 _ownerId;
        (_ownerId, ) = store.networks(id);
        address primaryAddress = store.getUserAddress(_ownerId, 0);

        store.setNetwork(id, bytes16(""), "", "", status);

        emit NetworkStatusChanged(primaryAddress, id, status);
    }

    function registerTracker(bytes16 id, bytes16 ownerId, bytes16 networkId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.trackers(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(ownerId, 0);

        store.setTracker(id, ownerId, networkId, name, dataUrl, HoQuStorageSchema.Status.Created);
        emit TrackerRegistered(primaryAddress, id, name);
    }

    function setTrackerStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.trackers(id);
        require(_status != HoQuStorageSchema.Status.NotExists);

        bytes16 _ownerId;
        (_ownerId, ) = store.trackers(id);
        address primaryAddress = store.getUserAddress(_ownerId, 0);

        store.setTracker(id, bytes16(""), bytes16(""), "", "", status);

        emit TrackerStatusChanged(primaryAddress, id, status);
    }

    function addOffer(bytes16 id, bytes16 ownerId, bytes16 networkId, bytes16 merchantId, address payerAddress, string name, string dataUrl, uint256 cost) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.offers(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(ownerId, 0);

        store.setOffer(id, ownerId, networkId, merchantId, payerAddress, name, dataUrl, cost, HoQuStorageSchema.Status.Created);
        emit OfferAdded(primaryAddress, id, name);
    }

    function setOfferStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.offers(id);
        require(_status != HoQuStorageSchema.Status.NotExists);

        bytes16 _ownerId;
        (_ownerId, ) = store.offers(id);
        address primaryAddress = store.getUserAddress(_ownerId, 0);

        store.setOffer(id, bytes16(""), bytes16(""), bytes16(""), address(0), "", "", 0, status);

        emit OfferStatusChanged(primaryAddress, id, status);
    }

    function addAdCampaign(bytes16 id, bytes16 ownerId, bytes16 offerId, address contractAddress) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.adCampaigns(id);
        require(_status == HoQuStorageSchema.Status.NotExists);
        address primaryAddress = store.getUserAddress(ownerId, 0);

        store.setAdCampaign(id, ownerId, offerId, contractAddress, HoQuStorageSchema.Status.Created);
        emit AdCampaignAdded(primaryAddress, id, contractAddress);
    }

    function setAdCampaignStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Status _status;
        (, _status) = store.adCampaigns(id);
        require(_status != HoQuStorageSchema.Status.NotExists);

        bytes16 _ownerId;
        (_ownerId, ) = store.adCampaigns(id);
        address primaryAddress = store.getUserAddress(_ownerId, 0);

        store.setAdCampaign(id, bytes16(""), bytes16(""), address(0), status);

        emit AdCampaignStatusChanged(primaryAddress, id, status);
    }

    function addLead(bytes16 id, bytes16 adCampaignId, bytes16 trackerId, string meta, string dataUrl, uint256 price) public onlyOwner {
        HoQuAdCampaignI adContract = adCampaignContract(adCampaignId);
        adContract.addLead(id, trackerId, meta, dataUrl, price);

        emit LeadAdded(address(adContract), adCampaignId, id);
    }

    function addLeadIntermediary(bytes16 id, bytes16 adCampaignId, address intermediaryAddress, uint32 percent) public onlyOwner {
        HoQuAdCampaignI adContract = adCampaignContract(adCampaignId);
        adContract.addLeadIntermediary(id, intermediaryAddress, percent);
    }

    function transactLead(bytes16 id, bytes16 adCampaignId) public onlyOwner {
        HoQuAdCampaignI adContract = adCampaignContract(adCampaignId);
        adContract.transactLead(id);

        emit LeadTransacted(address(adContract), adCampaignId, id);
    }

    function setLeadStatus(bytes16 id, bytes16 adCampaignId, HoQuStorageSchema.Status _status) public onlyOwner {
        HoQuAdCampaignI adContract = adCampaignContract(adCampaignId);
        adContract.setLeadStatus(id, _status);
    }

    function adCampaignContract(bytes16 adCampaignId) internal returns (HoQuAdCampaignI) {
        address _contractAddress;
        uint _createdAt;
        HoQuStorageSchema.Status _status;
        (, _contractAddress, _createdAt, _status) = store.adCampaigns(adCampaignId);
        require(_status != HoQuStorageSchema.Status.NotExists);

        return HoQuAdCampaignI(_contractAddress);
    }
}