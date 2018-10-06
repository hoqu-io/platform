pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorageAccessor.sol';
import './HoQuAdCampaignI.sol';

contract HoQuPlatform is HoQuStorageAccessor {
    using SafeMath for uint256;

    event UserRegistered(address indexed ownerAddress, bytes16 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress, bytes16 id);
    event UserPubKeyUpdated(address indexed ownerAddress, bytes16 id);
    event UserStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event IdentificationAdded(address indexed ownerAddress, bytes16 id, bytes16 userId, string name);
    event KycReportAdded(address indexed ownerAddress, HoQuStorageSchema.KycLevel kycLevel, bytes16 id, bytes16 userId);
    event CompanyRegistered(address indexed ownerAddress, bytes16 id, string name);
    event CompanyStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event NetworkRegistered(address indexed ownerAddress, bytes16 id, string name);
    event NetworkStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event TrackerRegistered(address indexed ownerAddress, bytes16 id, string name);
    event TrackerStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event OfferAdded(address indexed ownerAddress, bytes16 id, string name);
    event OfferTariffAdded(address indexed ownerAddress, bytes16 id, bytes16 tariff_id);
    event OfferStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event AdCampaignAdded(address indexed ownerAddress, bytes16 id, address contractAddress);
    event AdCampaignStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);
    event LeadAdded(address indexed contractAddress, bytes16 adCampaignId, bytes16 id);
    event LeadTransacted(address indexed contractAddress, bytes16 adCampaignId, bytes16 id);
    event TariffAdded(address indexed ownerAddress, bytes16 id, string name);
    event TariffStatusChanged(address indexed ownerAddress, bytes16 id, HoQuStorageSchema.Status status);

    constructor(
        address configAddress,
        address storageAddress
    ) HoQuStorageAccessor(
        configAddress,
        storageAddress
    ) public {}

    function registerUser(bytes16 id, string role, address ownerAddress, string pubKey) public onlyOwner {
        HoQuStorageSchema.User memory user = getUser(id);
        require(user.status == HoQuStorageSchema.Status.NotExists);

        user.ownerAddress = ownerAddress;
        user.role = role;
        user.pubKey = pubKey;
        setUser(id, user);

        emit UserRegistered(ownerAddress, id, role);
    }

    function addUserAddress(bytes16 id, address ownerAddress) public onlyOwner {
        addUserAddressInternal(id, ownerAddress);

        address primaryAddress = getUserAddress(id, 0);
        emit UserAddressAdded(primaryAddress, ownerAddress, id);
    }

    function updateUserPubKey(bytes16 id, string pubKey) public onlyOwner {
        address primaryAddress = getUserAddress(id, 0);

        HoQuStorageSchema.User memory user = getUser(id);
        user.pubKey = pubKey;
        setUser(id, user);

        emit UserPubKeyUpdated(primaryAddress, id);
    }

    function setUserStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        address primaryAddress = getUserAddress(id, 0);

        HoQuStorageSchema.User memory user = getUser(id);
        user.status = status;

        setUser(id, user);

        emit UserStatusChanged(primaryAddress, id, status);
    }

    function addIdentification(bytes16 id, bytes16 userId, string idType, string name, bytes16 companyId) public onlyOwner {
        HoQuStorageSchema.Identification memory identification = getIdentification(id);
        require(identification.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(userId, 0);

        identification.userId = userId;
        identification.idType =idType;
        identification.name = name;
        identification.companyId = companyId;

        setIdentification(id, identification);

        emit IdentificationAdded(primaryAddress, id, userId, name);
    }

    function addKycReport(bytes16 id, string meta, HoQuStorageSchema.KycLevel kycLevel, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Identification memory identification = getIdentification(id);
        address primaryAddress = getUserAddress(identification.userId, 0);

        HoQuStorageSchema.KycReport memory kyc;
        kyc.meta = meta;
        kyc.kycLevel = kycLevel;
        kyc.dataUrl = dataUrl;

        addKyc(id, kyc);

        HoQuStorageSchema.User memory user = getUser(id);
        user.kycLevel = kycLevel;
        setUser(identification.userId, user);

        emit KycReportAdded(primaryAddress, kycLevel, id, identification.userId);
    }

    function getKycReport(bytes16 id, uint16 num) public constant returns (uint, string, HoQuStorageSchema.KycLevel, string) {
        return store.getKycReport(id, num);
    }

    function registerCompany(bytes16 id, bytes16 ownerId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Company memory company = getCompany(id);
        require(company.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        company.ownerId = ownerId;
        company.name = name;
        company.dataUrl = dataUrl;

        setCompany(id, company);

        emit CompanyRegistered(primaryAddress, id, name);
    }

    function setCompanyStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Company memory company = getCompany(id);
        require(company.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(company.ownerId, 0);

        company.status = status;
        setCompany(id, company);

        emit CompanyStatusChanged(primaryAddress, id, status);
    }

    function registerNetwork(bytes16 id, bytes16 ownerId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Network memory network = getNetwork(id);
        require(network.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        network.ownerId = ownerId;
        network.name = name;
        network.dataUrl = dataUrl;

        setNetwork(id, network);

        emit NetworkRegistered(primaryAddress, id, name);
    }

    function setNetworkStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Network memory network = getNetwork(id);
        require(network.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(network.ownerId, 0);

        network.status = status;
        setNetwork(id, network);

        emit NetworkStatusChanged(primaryAddress, id, status);
    }

    function registerTracker(bytes16 id, bytes16 ownerId, bytes16 networkId, string name, string dataUrl) public onlyOwner {
        HoQuStorageSchema.Tracker memory tracker = getTracker(id);
        require(tracker.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        tracker.ownerId = ownerId;
        tracker.networkId = networkId;
        tracker.name = name;
        tracker.dataUrl = dataUrl;

        setTracker(id, tracker);

        emit TrackerRegistered(primaryAddress, id, name);
    }

    function setTrackerStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Tracker memory tracker = getTracker(id);
        require(tracker.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(tracker.ownerId, 0);

        tracker.status = status;
        setTracker(id, tracker);

        emit TrackerStatusChanged(primaryAddress, id, status);
    }

    function addOffer(bytes16 id, bytes16 ownerId, bytes16 networkId, bytes16 merchantId, address payerAddress, string name, string dataUrl, uint256 cost) public onlyOwner {
        HoQuStorageSchema.Offer memory offer = getOffer(id);
        require(offer.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        offer.ownerId = ownerId;
        offer.networkId = networkId;
        offer.merchantId = merchantId;
        offer.payerAddress = payerAddress;
        offer.name = name;
        offer.dataUrl = dataUrl;
        offer.cost = cost;

        setOffer(id, offer);

        emit OfferAdded(primaryAddress, id, name);
    }

    function addOfferTariff(bytes16 id, bytes16 tariff_id) public onlyOwner {
        HoQuStorageSchema.Offer memory offer = getOffer(id);
        address ownerAddress = getUserAddress(offer.ownerId, 0);

        addOfferTariffInternal(id, tariff_id);
        emit OfferTariffAdded(ownerAddress, id, tariff_id);
    }

    function setOfferTariff(bytes16 id, uint8 num, bytes16 tariff_id) public onlyOwner {
        HoQuStorageSchema.Offer memory offer = getOffer(id);
        address ownerAddress = getUserAddress(offer.ownerId, 0);

        setOfferTariffInternal(id, num, tariff_id);
        emit OfferTariffAdded(ownerAddress, id, tariff_id);
    }

    function setOfferStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Offer memory offer = getOffer(id);
        require(offer.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(offer.ownerId, 0);

        offer.status = status;
        setOffer(id, offer);

        emit OfferStatusChanged(primaryAddress, id, status);
    }

    function addAdCampaign(bytes16 id, bytes16 ownerId, bytes16 offerId, address contractAddress) public onlyOwner {
        HoQuStorageSchema.AdCampaign memory adCampaign = getAdCampaign(id);
        require(adCampaign.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        adCampaign.ownerId = ownerId;
        adCampaign.offerId = offerId;
        adCampaign.contractAddress = contractAddress;

        setAdCampaign(id, adCampaign);

        emit AdCampaignAdded(primaryAddress, id, contractAddress);
    }

    function setAdCampaignStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.AdCampaign memory adCampaign = getAdCampaign(id);
        require(adCampaign.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(adCampaign.ownerId, 0);

        adCampaign.status = status;
        setAdCampaign(id, adCampaign);

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
        HoQuStorageSchema.AdCampaign memory adCampaign = getAdCampaign(adCampaignId);
        require(adCampaign.status != HoQuStorageSchema.Status.NotExists);

        return HoQuAdCampaignI(adCampaign.contractAddress);
    }

    function addTariff(bytes16 id, bytes16 ownerId, string name, string action, string calcMethod, uint256 price) public onlyOwner {
        HoQuStorageSchema.Tariff memory tariff = getTariff(id);
        require(tariff.status == HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(ownerId, 0);

        tariff.ownerId = ownerId;
        tariff.name = name;
        tariff.action = action;
        tariff.calcMethod = calcMethod;
        tariff.price = price;

        setTariff(id, tariff);

        emit TariffAdded(primaryAddress, id, name);
    }

    function setTariffStatus(bytes16 id, HoQuStorageSchema.Status status) public onlyOwner {
        HoQuStorageSchema.Tariff memory tariff = getTariff(id);
        require(tariff.status != HoQuStorageSchema.Status.NotExists);

        address primaryAddress = getUserAddress(tariff.ownerId, 0);

        tariff.status = status;
        setTariff(id, tariff);

        emit TariffStatusChanged(primaryAddress, id, status);
    }
}