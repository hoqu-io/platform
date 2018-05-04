pragma solidity ^0.4.23;

contract HoQuStorageSchema {
    enum Status {NotExists, Created, Pending, Active, Done, Declined}
    enum KycLevel {Undefined, Tier1, Tier2, Tier3, Tier4, Tier5}

    struct User {
        mapping (uint8 => address) addresses;
        uint8 numOfAddresses;
        string role;
        KycLevel kycLevel;
        string pubKey;
        uint createdAt;
        Status status;
    }

    struct Identification {
        bytes16 userId;
        bytes16 companyId;
        string idType;
        string name;
        mapping (uint16 => KycReport) kycReports;
        uint16 numOfKycReports;
        uint createdAt;
        Status status;
    }

    struct KycReport {
        string meta;
        KycLevel kycLevel;
        string dataUrl;
        uint createdAt;
    }

    struct Stats {
        uint256 rating;
        uint256 volume;
        uint256 contragents;
        uint256 stat1;
        uint256 stat2;
        Status status;
    }

    struct Company {
        bytes16 ownerId;
        string name;
        string dataUrl;
        uint createdAt;
        Status status;
    }

    struct Network {
        bytes16 ownerId;
        string name;
        string dataUrl;
        uint createdAt;
        Status status;
    }

    struct Tracker {
        bytes16 ownerId;
        bytes16 networkId;
        string name;
        string dataUrl;
        uint createdAt;
        Status status;
    }

    struct Offer {
        bytes16 ownerId;
        bytes16 networkId;
        bytes16 merchantId;
        address payerAddress;
        string name;
        string dataUrl;
        uint256 cost;
        uint createdAt;
        Status status;
    }

    struct AdCampaign {
        bytes16 ownerId;
        bytes16 offerId;
        address contractAddress;
        uint createdAt;
        Status status;
    }
}