pragma solidity ^0.4.23;

contract HoQuRaterI {
    function processAddLead(bytes16 offerId, bytes16 trackerId, bytes16 affiliateId, uint256 price) public;
    function processTransactLead(bytes16 offerId, bytes16 trackerId, bytes16 affiliateId, uint256 price) public;
}