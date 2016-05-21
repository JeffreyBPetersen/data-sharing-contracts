/*
    general assumptions:
    Anyone directly interacting with the system is represented by either an account key or contract.
        Representation via contract allows for arbitrarily complex logic to be involved in taking actions through it.
            A simple case would be requiring multiple signatures from within the represented organization.
    Any tasks which don't notably benefit from an irrefutable public record are better suited to implementation within programs other than the contracts themselves.
        This keeps the contracts cheap to operate and affords significantly more flexibility in later changes to how the overall system functions.
        A major case would be interfaces that filter stewards to only display those that meet the requirements for official recognition.
    It is significantly easier and cheaper to control which content is visible in interfaces to contracts than to limit what content can be added to the contracts
*/

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

/*
    This is a relatively minimal version of recorded data sharing.
    It only tracks registered copies of files, when they're requested, and when they're shared.
    All storage and transfer of the encrypted files is handled by the IPFS portion of the overall system.
    
    example usage:
    A steward wants to add a new file to the system.
    The steward creates a new cryptographic keypair and keeps both keys (A and B) secret to start.
    The steward encrypts the file with key A, hashes the encrypted file, then calls "upload" with the hash.
    A number is assigned to the file and a record is stored that notes the account responsible for managing access to it.
    A researcher later wants access to the file.
    The researcher formally makes a request by calling "requestFile" with the number of the file they want access to.
    The steward is notified by a "Request" event with a file number that passes a filter to only files they manage.
    The steward formally shares the file by calling "shareFile" with the number of the file and the digital address of the recipient.
    The steward then uses any secure means of messaging to send key B to the researcher.
*/
contract BasicDataSharingRecord {
    
    // events act as notifications that are sent across the network
    event FileRequested(uint fileNumber, address requester);
    event FileShared(uint fileNumber, address recipient);
    
    struct File {
        address manager;
        bytes32 hash;
        mapping (address => bool) sharedWith;
        mapping (address => bool) requestedBy;
    }
    
    mapping (uint => File) files; // files numbered by order in which they were uploaded
    uint public nextFileNumber; // number for next file uploaded
    
    function upload(bytes32 hash){
        files[nextFileNumber++] = File(msg.sender, hash);
    }
    
    function shareFile(uint fileNumber, address recipient){
        if(files[fileNumber].manager != msg.sender) throw; // you're only allowed to share files you uploaded
        files[fileNumber].sharedWith[recipient] = true;
        FileShared(fileNumber, recipient);
    }
    
    function requestFile(uint fileNumber){
        files[fileNumber].requestedBy[msg.sender] = true;
        FileRequested(fileNumber, msg.sender);
    }
    
    function getManager(uint fileNumber) returns (address manager){
        return files[fileNumber].manager;
    }
    
    function getHash(uint fileNumber) constant returns (bytes32 hash){
        return files[fileNumber].hash;
    }
    
    function getIsSharedWith(uint fileNumber, address potentiallySharedWith) constant returns (bool isSharedWith){
        return files[fileNumber].sharedWith[potentiallySharedWith];
    }
    
    function getWasRequestedBy(uint fileNumber, address potentiallyRequestedBy) constant returns (bool wasRequestedBy){
        return files[fileNumber].requestedBy[potentiallyRequestedBy];
    }
    
    /*
        potential additions to the contract:
        arbitrary additional metadata fields for each file
            such as using "mapping (string => string) metadata" and having a function to set it that is only usable by the manager of the file
                would possibly need to be "mapping (bytes32 => string)" type in practice due to current limitations of solidity
            examples: "derived from file #", "using licence agreement #n", "cancer type", "anonymized participant identifier", "contact info"...
        specific additional metadata fields for each file
            may make contract operation cheaper overall by making very common fields into defaults
        transferable manager role
            as opposed to adding another record of the file for each new manager
        timed sharing
            purely for convenience as a legal statement, not enforceable in code
        agreement handling address
            for convenience and clarity in referring to a corresponding SignedAgreementRecord contract
        flagging
            for publicly calling out unauthorized use of data
            well behaving storage providers could automatically stop sharing full files when flags need to be reviewed
        
        potential extensions on top of the contract:
        smart licenses
            other contracts which act as managers and can contain arbitrary logic for when a file is formally shared
                for example: automatically check for signatures in a SignedAgreementRecord contract and collect data handling fees before sharing
                    data handling fees covering things like costs of data storage and compliance with legal requirements
        curation services
            identify which files are worth requesting for any particular purpose
            optionally smart contract based whenever a public record of curation is required
                such as for programmed incentives that reward high quality data
    */
}
