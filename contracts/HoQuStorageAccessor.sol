pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuConfig.sol';
import './HoQuStorageSchema.sol';
import './HoQuStorage.sol';

contract HoQuStorageAccessor {
    using SafeMath for uint256;

    HoQuConfig public config;
    HoQuStorage public store;

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

    function getUser(bytes16 id) internal returns (HoQuStorageSchema.User) {
        HoQuStorageSchema.User memory user;
        (user.ownerAddress, user.numOfAddresses, user.role, user.kycLevel, user.pubKey, user.createdAt, user.status) = store.users(id);

        return user;
    }

    function setUser(bytes16 id, HoQuStorageSchema.User user) internal {
        return store.setUser(id, user.role, user.ownerAddress, user.kycLevel, user.pubKey, user.status);
    }

    function addUserAddressInternal(bytes16 id, address ownerAddress) internal {
        return store.addUserAddress(id, ownerAddress);
    }

    function getUserAddress(bytes16 id, uint8 num) public constant returns (address) {
        return store.getUserAddress(id, num);
    }
    
    function getIdentification(bytes16 id) internal returns (HoQuStorageSchema.Identification) {
        HoQuStorageSchema.Identification memory identification;
        (identification.userId, identification.companyId, identification.idType, identification.name, identification.numOfKycReports, identification.createdAt, identification.status) = store.ids(id);

        return identification;
    }

    function setIdentification(bytes16 id, HoQuStorageSchema.Identification identification) internal {
        return store.setIdentification(id, identification.userId, identification.idType, identification.name, identification.companyId, identification.status);
    }
    
    function getKyc(bytes16 id, uint16 num) internal returns (HoQuStorageSchema.KycReport) {
        HoQuStorageSchema.KycReport memory kycReport;
        (kycReport.createdAt, kycReport.meta, kycReport.kycLevel, kycReport.dataUrl) = store.getKycReport(id, num);

        return kycReport;
    }

    function addKyc(bytes16 id, HoQuStorageSchema.KycReport kycReport) internal {
        return store.addKycReport(id, kycReport.meta, kycReport.kycLevel, kycReport.dataUrl);
    }

    function getStats(bytes16 id) internal returns (HoQuStorageSchema.Stats) {
        HoQuStorageSchema.Stats memory stats;
        (stats.rating, stats.volume, stats.members, stats.alfa, stats.beta, stats.status) = store.stats(id);

        return stats;
    }

    function setStats(bytes16 id, bytes16 userId, HoQuStorageSchema.Stats stats) internal {
        return store.setStats(id, userId, stats.rating, stats.volume, stats.members, stats.alfa, stats.beta, stats.status);
    }

    function getCompany(bytes16 id) internal returns (HoQuStorageSchema.Company) {
        HoQuStorageSchema.Company memory company;
        (company.ownerId, company.name, company.dataUrl, company.createdAt, company.status) = store.companies(id);

        return company;
    }

    function setCompany(bytes16 id, HoQuStorageSchema.Company company) internal {
        return store.setCompany(id, company.ownerId, company.name, company.dataUrl, company.status);
    }

    function getNetwork(bytes16 id) internal returns (HoQuStorageSchema.Network) {
        HoQuStorageSchema.Network memory network;
        (network.ownerId, network.name, network.dataUrl, network.createdAt, network.status) = store.networks(id);

        return network;
    }

    function setNetwork(bytes16 id, HoQuStorageSchema.Network network) internal {
        return store.setNetwork(id, network.ownerId, network.name, network.dataUrl, network.status);
    }

    function getTracker(bytes16 id) internal returns (HoQuStorageSchema.Tracker) {
        HoQuStorageSchema.Tracker memory tracker;
        (tracker.ownerId, tracker.networkId, tracker.name, tracker.dataUrl, tracker.createdAt, tracker.status) = store.trackers(id);

        return tracker;
    }

    function setTracker(bytes16 id, HoQuStorageSchema.Tracker tracker) internal {
        return store.setTracker(id, tracker.ownerId, tracker.networkId, tracker.name, tracker.dataUrl, tracker.status);
    }

    function getOffer(bytes16 id) internal returns (HoQuStorageSchema.Offer) {
        HoQuStorageSchema.Offer memory offer;
        (offer.ownerId, offer.networkId, offer.merchantId, offer.payerAddress, offer.name, offer.dataUrl, offer.cost,) = store.offers(id);
	    (, offer.createdAt, offer.status) = store.offers(id);

        return offer;
    }

    function setOffer(bytes16 id, HoQuStorageSchema.Offer offer) internal {
        return store.setOffer(id, offer.ownerId, offer.networkId, offer.merchantId, offer.payerAddress, offer.name, offer.dataUrl, offer.cost, offer.status);
    }

    function addOfferTariffInternal(bytes16 id, bytes16 tariff_id) internal {
        return store.addOfferTariff(id, tariff_id);
    }

    function setOfferTariffInternal(bytes16 id, uint8 num, bytes16 tariff_id) internal {
        return store.setOfferTariff(id, num, tariff_id);
    }

    function getOfferTariff(bytes16 id, uint8 num) public constant returns (bytes16) {
        return store.getOfferTariff(id, num);
    }

    function getAdCampaign(bytes16 id) internal returns (HoQuStorageSchema.AdCampaign) {
        HoQuStorageSchema.AdCampaign memory adCampaign;
        (adCampaign.ownerId, adCampaign.offerId, adCampaign.contractAddress, adCampaign.createdAt, adCampaign.status) = store.adCampaigns(id);

        return adCampaign;
    }

    function setAdCampaign(bytes16 id, HoQuStorageSchema.AdCampaign adCampaign) internal {
        return store.setAdCampaign(id, adCampaign.ownerId, adCampaign.offerId, adCampaign.contractAddress, adCampaign.status);
    }

    function getTariff(bytes16 id) internal returns (HoQuStorageSchema.Tariff) {
        HoQuStorageSchema.Tariff memory tariff;
        (tariff.ownerId, tariff.name, tariff.action, tariff.calcMethod, tariff.price,) = store.tariffs(id);
        (, tariff.createdAt, tariff.status) = store.tariffs(id);

        return tariff;
    }

    function setTariff(bytes16 id, HoQuStorageSchema.Tariff tariff) internal {
        return store.setTariff(id, tariff.ownerId, tariff.name, tariff.action, tariff.calcMethod, tariff.price, tariff.status);
    }
}