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
    mapping (bytes16 => Tariff) public tariffs;

    event UserRegistered(address indexed ownerAddress, bytes16 id, string role);
    event UserAddressAdded(address indexed ownerAddress, address additionalAddress, bytes16 id);
    event StatsChanged(address indexed ownerAddress, bytes16 id, uint256 rating);
    event IdentificationAdded(address indexed ownerAddress, bytes16 id, bytes16 userId, string name);
    event KycReportAdded(address indexed ownerAddress, KycLevel kycLevel);
    event CompanyRegistered(address indexed ownerAddress, bytes16 id, string name);
    event NetworkRegistered(address indexed ownerAddress, bytes16 id, string name);
    event TrackerRegistered(address indexed ownerAddress, bytes16 id, string name);
    event OfferAdded(address indexed ownerAddress, bytes16 id, string name);
    event OfferTariffAdded(address indexed ownerAddress, bytes16 id, bytes16 tariff_id);
    event AdCampaignAdded(address indexed ownerAddress, bytes16 id, address contractAddress);
    event TariffAdded(address indexed ownerAddress, bytes16 id, string name);

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
                ownerAddress: ownerAddress,
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

        emit UserAddressAdded(users[id].addresses[0], ownerAddress, id);
    }

    function getUserAddress(bytes16 id, uint8 num) public constant returns (address) {
        require(users[id].status != Status.NotExists);

        return users[id].addresses[num];
    }

    function setIdentification(bytes16 id, bytes16 userId, string idType, string name, bytes16 companyId, Status status) public onlyOwner {
        if (ids[id].status == Status.NotExists) {
            address ownerAddress = getUserAddress(userId, 0);

            ids[id] = Identification({
                createdAt : now,
                userId : userId,
                idType : idType,
                name: name,
                companyId : companyId,
                numOfKycReports : 0,
                status : Status.Created
            });

            emit IdentificationAdded(ownerAddress, id, userId, name);
        } else {
            if (bytes(idType).length != 0) {
                ids[id].idType = idType;
            }
            if (companyId.length != 0) {
                ids[id].companyId = companyId;
            }
            if (status != Status.NotExists) {
                ids[id].status = status;
            }
        }
    }

    function setStats(bytes16 id, bytes16 userId, uint256 rating, uint256 volume, uint256 members, uint256 alfa, uint256 beta, Status status) public onlyOwner {
        if (stats[id].status == Status.NotExists) {
            address ownerAddress = userId.length > 0 ? getUserAddress(userId, 0) : address(0);

            stats[id] = Stats({
                rating : rating,
                volume : volume,
                members : members,
                alfa : alfa,
                beta : beta,
                status : Status.Created
            });
            if (userId.length > 0) {
                stats[userId] = stats[id];
            }

            emit StatsChanged(ownerAddress, id, rating);
        } else {
            if (rating != 0) {
                stats[id].rating = rating;
                if (userId.length > 0) {
                    stats[userId].rating = rating;
                }
            }
            if (volume != 0) {
                stats[id].volume = volume;
                if (userId.length > 0) {
                    stats[userId].volume = volume;
                }
            }
            if (members != 0) {
                stats[id].members = members;
                if (userId.length > 0) {
                    stats[userId].members = members;
                }
            }
            if (alfa != 0) {
                stats[id].alfa = alfa;
                if (userId.length > 0) {
                    stats[userId].alfa = alfa;
                }
            }
            if (beta != 0) {
                stats[id].beta = beta;
                if (userId.length > 0) {
                    stats[userId].beta = beta;
                }
            }
            if (status != Status.NotExists) {
                stats[id].status = status;
            }
        }
    }

    function addKycReport(bytes16 id, string meta, KycLevel kycLevel, string dataUrl) public onlyOwner {
        require(ids[id].status != Status.NotExists);

        ids[id].kycReports[ids[id].numOfKycReports] = KycReport({
            createdAt : now,
            meta : meta,
            kycLevel : kycLevel,
            dataUrl : dataUrl
        });
        ids[id].numOfKycReports++;

        emit KycReportAdded(users[ids[id].userId].addresses[0], kycLevel);
    }

    function getKycReport(bytes16 id, uint16 num) public constant returns (uint, string, KycLevel, string) {
        require(ids[id].status != Status.NotExists);

        return (
            ids[id].kycReports[num].createdAt,
            ids[id].kycReports[num].meta,
            ids[id].kycReports[num].kycLevel,
            ids[id].kycReports[num].dataUrl
        );
    }

    function setCompany(bytes16 id, bytes16 ownerId, string name, string dataUrl, Status status) public onlyOwner {
        if (companies[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);
            require(users[ownerId].addresses[0] != address(0));

            companies[id] = Company({
                createdAt : now,
                ownerId : ownerId,
                name : name,
                dataUrl : dataUrl,
                status : Status.Created
            });
    
            emit CompanyRegistered(users[ownerId].addresses[0], id, name);
        } else {
            if (bytes(name).length != 0) {
                companies[id].name = name;
            }
            if (bytes(dataUrl).length != 0) {
                companies[id].dataUrl = dataUrl;
            }
            if (status != Status.NotExists) {
                companies[id].status = status;
            }
        }
    }

    function setNetwork(bytes16 id, bytes16 ownerId, string name, string dataUrl, Status status) public onlyOwner {
        if (networks[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);
            require(users[ownerId].addresses[0] != address(0));

            networks[id] = Network({
                createdAt : now,
                ownerId : ownerId,
                name : name,
                dataUrl : dataUrl,
                status : Status.Created
            });

            emit NetworkRegistered(users[ownerId].addresses[0], id, name);
        } else {
            if (bytes(name).length != 0) {
                networks[id].name = name;
            }
            if (bytes(dataUrl).length != 0) {
                networks[id].dataUrl = dataUrl;
            }
            if (status != Status.NotExists) {
                networks[id].status = status;
            }
        }
    }
    
    function setTracker(bytes16 id, bytes16 ownerId, bytes16 networkId, string name, string dataUrl, Status status) public onlyOwner {
        if (networkId.length != 0) {
            require(networks[networkId].status != Status.NotExists);
        }

        if (trackers[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);
            require(users[ownerId].addresses[0] != address(0));

            trackers[id] = Tracker({
                createdAt : now,
                ownerId : ownerId,
                networkId : networkId,
                name : name,
                dataUrl : dataUrl,
                status : Status.Created
            });

            emit TrackerRegistered(users[ownerId].addresses[0], id, name);
        } else {
            if (networkId.length != 0) {
                trackers[id].networkId = networkId;
            }
            if (bytes(name).length != 0) {
                trackers[id].name = name;
            }
            if (bytes(dataUrl).length != 0) {
                trackers[id].dataUrl = dataUrl;
            }
            if (status != Status.NotExists) {
                trackers[id].status = status;
            }
        }
    }

    function setOffer(bytes16 id, bytes16 ownerId, bytes16 networkId, bytes16 merchantId, address payerAddress, string name, string dataUrl, uint256 cost, Status status) public onlyOwner {
        if (networkId.length != 0) {
            require(networks[networkId].status != Status.NotExists);
        }
        if (merchantId.length != 0) {
            require(users[merchantId].status != Status.NotExists);
        }

        if (trackers[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);
            require(users[ownerId].addresses[0] != address(0));

            offers[id] = Offer({
                createdAt : now,
                networkId : networkId,
                merchantId: merchantId,
                ownerId : ownerId,
                payerAddress : payerAddress,
                name : name,
                dataUrl : dataUrl,
                cost : cost,
                numOfTariffs: 0,
                status : Status.Created
            });

            emit OfferAdded(payerAddress, id, name);
        } else {
            if (networkId.length != 0) {
                offers[id].networkId = networkId;
            }
            if (merchantId.length != 0) {
                offers[id].merchantId = merchantId;
            }
            if (payerAddress != address(0)) {
                offers[id].payerAddress = payerAddress;
            }
            if (bytes(name).length != 0) {
                offers[id].name = name;
            }
            if (bytes(dataUrl).length != 0) {
                offers[id].dataUrl = dataUrl;
            }
            if (cost != 0) {
                offers[id].cost = cost;
            }
            if (status != Status.NotExists) {
                offers[id].status = status;
            }
        }
    }

    function addOfferTariff(bytes16 id, bytes16 tariff_id) public onlyOwner {
        require(offers[id].status != Status.NotExists);

        offers[id].tariffs[offers[id].numOfTariffs] = tariff_id;
        offers[id].numOfTariffs++;

        address ownerAddress = getUserAddress(offers[id].ownerId, 0);

        emit OfferTariffAdded(ownerAddress, id, tariff_id);
    }

    function setOfferTariff(bytes16 id, uint8 num, bytes16 tariff_id) public onlyOwner {
        require(offers[id].status != Status.NotExists);
        require(offers[id].tariffs[num] != 0);

        offers[id].tariffs[num] = tariff_id;

        address ownerAddress = getUserAddress(offers[id].ownerId, 0);

        emit OfferTariffAdded(ownerAddress, id, tariff_id);
    }

    function getOfferTariff(bytes16 id, uint8 num) public constant returns (bytes16) {
        require(offers[id].status != Status.NotExists);

        return offers[id].tariffs[num];
    }

    function setAdCampaign(bytes16 id, bytes16 ownerId, bytes16 offerId, address contractAddress, Status status) public onlyOwner {
        if (trackers[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);
            require(users[ownerId].addresses[0] != address(0));
            require(offers[offerId].status != Status.NotExists);

            address ownerAddress = getUserAddress(ownerId, 0);

            adCampaigns[id] = AdCampaign({
                createdAt : now,
                offerId : offerId,
                ownerId : ownerId,
                contractAddress : contractAddress,
                status : Status.Created
            });

            emit AdCampaignAdded(ownerAddress, id, contractAddress);
        } else {
            if (contractAddress != address(0)) {
                adCampaigns[id].contractAddress = contractAddress;
            }
            if (status != Status.NotExists) {
                adCampaigns[id].status = status;
            }
        }
    }

    function setTariff(bytes16 id, bytes16 ownerId, string name, string action, string calcMethod, uint256 price, Status status) public onlyOwner {
        if (tariffs[id].status == Status.NotExists) {
            require(users[ownerId].status != Status.NotExists);

            address ownerAddress = getUserAddress(ownerId, 0);

            tariffs[id] = Tariff({
                createdAt : now,
                ownerId : ownerId,
                name : name,
                action : action,
                calcMethod : calcMethod,
                price : price,
                status : Status.Created
            });

            emit TariffAdded(ownerAddress, id, name);
        } else {
            if (bytes(name).length != 0) {
                tariffs[id].name = name;
            }
            if (bytes(action).length != 0) {
                tariffs[id].action = action;
            }
            if (bytes(calcMethod).length != 0) {
                tariffs[id].calcMethod = calcMethod;
            }
            if (price != 0) {
                tariffs[id].price = price;
            }
            if (status != Status.NotExists) {
                tariffs[id].status = status;
            }
        }
    }
}