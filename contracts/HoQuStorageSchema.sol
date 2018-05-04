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

}