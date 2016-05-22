/*
    use to upload records of agreements via hash and digitally sign agreements
    
    example usage:
    A copy of the steward requirements is uploaded to start. (https://docs.google.com/document/d/1tjVikBPxPgHQoq5wnqgrFVnz904-iEaI3ahxTci6yw4)
    When a new steward wants to join and receive official recognition, then they must sign the agreement.
    When a steward is adding a new participant to the system, then they must digitize the agreement made with the participant, upload it, and sign it.
    Any other agreements can be added to the record as needed.
    The main challenge/cost is likely establishing legal recognition for the stewards' digital signatures in order to begin using them.
*/
contract SignedAgreementRecord {
    struct Agreement {
        bytes32 hash;
        mapping (address => bool) signers;
    }
    
    mapping (uint => Agreement) agreementIDs;
    uint public nextAgreementID;
    
    function uploadAgreement(bytes32 hash){
        agreementIDs[nextAgreementID++].hash = hash;
    }
    
    function signAgreement(uint agreementID){
        agreementIDs[agreementID].signers[msg.sender] = true;
    }
    
    function getHash(uint agreementID) constant returns (bytes32 hash){
        return agreementIDs[agreementID].hash;
    }
    
    function getSignedBy(uint agreementID, address potentialSigner) constant returns (bool didSign){
        return agreementIDs[agreementID].signers[potentialSigner];
    }
}
