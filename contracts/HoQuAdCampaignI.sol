pragma solidity ^0.4.23;

import './HoQuStorageSchema.sol';

contract HoQuAdCampaignI {
    function addLead(bytes16 id, bytes16 trackerId, string meta, string dataUrl, uint256 price) public;
    function addLeadIntermediary(bytes16 id, address intermediaryAddress, uint32 percent) public;
    function transactLead(bytes16 id) public;
    function setLeadStatus(bytes16 id, HoQuStorageSchema.Status status) public;
}