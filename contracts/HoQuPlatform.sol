pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './HoQuToken.sol';
import './HoQuPlatformConfig.sol';

contract HoQuPlatform {
    using SafeMath for uint256;
    
    uint8 constant STATUS_NOT_EXIST = 0;
    uint8 constant STATUS_CREATED = 1;
    uint8 constant STATUS_PENDING = 2;
    uint8 constant STATUS_PROCESSING = 3; //really need it?
    uint8 constant STATUS_APPROVED = 4;
    uint8 constant STATUS_ACTIVE = 5;
    uint8 constant STATUS_DONE = 6; // == approved?
    uint8 constant STATUS_DECLINED = 7;
    uint8 constant STATUS_APPEALING = 8;

    HoQuPlatformConfig public config;

    HoQuToken public token;

    // HoQu platform commission in szabo = 0.5 szabo
    uint256 public commission;

    struct Network {
        address owner;
        string name;
        string url;
        uint8 status;
    }

    struct Offer {
        address owner;
        string networkId;
        string name;
        string url;
        uint256 cost;
        uint8 status;
    }

    struct Lead {
        address owner;
        string offerId;
        string url;
        string secret;
        string meta;
        uint256 price;
        uint8 status;
    }

    mapping(string => Network) networks;
    mapping(string => Offer) offers;
    mapping(string => Lead) leads;
    
    event NetworkActivated(string id);
    event OfferActivated(string id);
    event LeadAdded(string id, string offerId, string meta);
    event LeadApproved(string id);
    event LeadDeclined(string id);

    function HoQuPlatform(address configAddress, address tokenAddress, uint256 _commission) public {
        config = HoQuPlatformConfig(configAddress);
        token = HoQuToken(tokenAddress);
        commission = _commission;
    }

    function addNetwork(string id, string name, string url) public returns (bool) {
        require (bytes(id).length != 0 && networks[id].status == STATUS_NOT_EXIST);
    
        networks[id] = Network({
            owner: msg.sender,
            name: name,
            url: url,
            status: STATUS_CREATED
        });
    
        return true;
    }

    function activateNetwork(string id) public returns (bool) {
        require (msg.sender == config.systemOwner());
        require (bytes(id).length != 0 && networks[id].status != STATUS_NOT_EXIST);
    
        networks[id].status = STATUS_ACTIVE;
    
        NetworkActivated(id);
    
        return true;
    }
    
    function getNetwork(string id) public returns (string, string, uint8) {
        require (bytes(id).length != 0 && networks[id].status != STATUS_NOT_EXIST);
    
        return (networks[id].name, networks[id].url, networks[id].status);
    }
    
    function addOffer(string id, string networkId, string name, string url, uint256 cost) public returns (bool) {
        require (bytes(id).length != 0 && offers[id].status == STATUS_NOT_EXIST);
    
        require (bytes(networkId).length != 0 && networks[networkId].status == STATUS_ACTIVE);
    
        offers[id] = Offer({
            owner: msg.sender,
            networkId: networkId,
            name: name,
            url: url,
            cost: cost,
            status: STATUS_CREATED
        });
    
        return true;
    }
    
    function activateOffer(string id) public returns (bool) {
        require (msg.sender == config.systemOwner());
        require (bytes(id).length != 0 && offers[id].status != STATUS_NOT_EXIST);
        
        offers[id].status = STATUS_ACTIVE;
        
        OfferActivated(id);
    
        return true;
    }
    
    function getOffer(string id) public returns (string, string, string, uint256, uint8) {
        require (bytes(id).length != 0 && offers[id].status != STATUS_NOT_EXIST);
        
        return (offers[id].networkId, offers[id].name, offers[id].url, offers[id].cost, offers[id].status);
    }
    
    function addLead(string id, string offerId, string url, string secret, string meta) public returns (bool) {
        require (bytes(id).length != 0 && leads[id].status == STATUS_NOT_EXIST);
        
        require (bytes(offerId).length != 0 && offers[offerId].status == STATUS_ACTIVE);
    
        leads[id] = Lead({
            owner: msg.sender,
            offerId: offerId,
            url: url,
            secret: secret,
            meta: meta,
            price: 0,
            status: STATUS_PENDING
        });
        
        LeadAdded(id, offerId, meta);
        
        return true;
    }

    function approveLead(string id) public returns (bool) {
        require (bytes(id).length != 0 && leads[id].status == STATUS_PENDING);

        Lead lead = leads[id];
        Offer offer = offers[lead.offerId];
        
        require (offer.owner == msg.sender && offer.status == STATUS_ACTIVE);

        uint256 commission = offer.cost.mul(commission).div(1 szabo);
        uint256 amount = offer.cost.sub(commission);
        token.transferFrom(offer.owner, this, offer.cost);
        token.transfer(config.commissionWallet(), commission);
        token.transfer(lead.owner, amount);

        leads[id].price = amount;
        leads[id].status = STATUS_APPROVED;
        
        LeadApproved(id);

        return true;
    }
    
    function declineLead(string id) public returns (bool) {
        require (bytes(id).length != 0 && leads[id].status == STATUS_PENDING);
        
        Lead lead = leads[id];
        Offer offer = offers[lead.offerId];
        
        require (offer.owner == msg.sender && offer.status == STATUS_ACTIVE);
    
        leads[id].status = STATUS_DECLINED;
        
        LeadDeclined(id);
        
        return true;
    }
    
    function getLead(string id) public returns (string, string, string, uint256, uint8) {
        require (bytes(id).length != 0 && leads[id].status != STATUS_NOT_EXIST);
        
        return (leads[id].offerId, leads[id].url, leads[id].meta, leads[id].price, leads[id].status);
    }
    
    function getLeadSecret(string id) public returns (string) {
        require (bytes(id).length != 0 && leads[id].status == STATUS_APPROVED);
        
        Offer offer = offers[leads[id].offerId];
        require (msg.sender == offer.owner);
        
        return leads[id].secret;
    }
}