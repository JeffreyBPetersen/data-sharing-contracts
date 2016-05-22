// dependency, main contract below
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
    ExternalServiceRequestRecord
    
    example usage
        A researcher needs to perform analysis on data they aren't allowed direct access to
        The researcher opens their CGT client and enters details of the analysis they need performed remotely
            details including docker image for performing analysis, window in which it must be done, etc...
        The CGT client adds the provided details in to a prewritten comprehensive agreement.
        The client then
            hashes the agreement
            adds it to a SignedAgreementRecord contract
            signs it
            and in a connected ExternalServiceRequestRecord contract, calls requestService with the appropriate arguments and included payment
        The contract uses an event to notify the provider to whom the request was made and the arbitrator named in it.
        The arbitrator and provider review the details of the request and the corresponding agreement, then each sign off on it
        Once all three parties have signed off on the service request, the provider can finalize provision of the service and begin work
        If the researcher does not believe the work was done according to the corresponding agreement, then they may dispute it to begin arbitration
*/
contract ExternalServiceRequestRecord {
    
    SignedAgreementRecord agreementRecordProvider;
    
    struct ServiceRequest {
        uint agreementID;
        uint cost;
        uint disputeWindow;
        
        address user;
        address provider;
        address arbitrator;
        
        bool started; //? could be replaced by checking whether disputeWindowCloses == 0 instead, slightly cheaper to execute and harder to read
        bool disputed;
        bool ended; // either completed or withdrawn
        uint disputeWindowCloses;
    }
    
    mapping (uint => ServiceRequest) serviceRequestIDs;
    uint nextServiceRequestID;
    
    event NewRequest(uint serviceRequestID, address provider, address arbitrator);
    event RequestWithdrawn(uint serviceRequestID, address provider);
    event NewDispute(uint serviceRequestID, address arbitrator);
    
    function ExternalServiceRequestRecord(SignedAgreementRecord agreementRecordProviderAddress){
        agreementRecordProvider = agreementRecordProviderAddress;
    }
    
    function requestService(address provider, address arbitrator, uint agreementID, uint disputeWindow){
        serviceRequestIDs[nextServiceRequestID].user = msg.sender;
        serviceRequestIDs[nextServiceRequestID].provider = provider;
        serviceRequestIDs[nextServiceRequestID].arbitrator = arbitrator;
        serviceRequestIDs[nextServiceRequestID].agreementID = agreementID;
        serviceRequestIDs[nextServiceRequestID].disputeWindow = disputeWindow;
        serviceRequestIDs[nextServiceRequestID].cost = msg.value;
        NewRequest(nextServiceRequestID, provider, arbitrator);
        nextServiceRequestID++;
    }
    
    function finalizeServiceRequest(uint serviceRequestID){
        if(msg.sender != serviceRequestIDs[serviceRequestID].provider ||
        serviceRequestIDs[serviceRequestID].ended ||
        !agreementRecordProvider.getSignedBy(serviceRequestIDs[serviceRequestID].agreementID, serviceRequestIDs[serviceRequestID].user) ||
        !agreementRecordProvider.getSignedBy(serviceRequestIDs[serviceRequestID].agreementID, serviceRequestIDs[serviceRequestID].provider) ||
        !agreementRecordProvider.getSignedBy(serviceRequestIDs[serviceRequestID].agreementID, serviceRequestIDs[serviceRequestID].arbitrator)) throw;
        serviceRequestIDs[serviceRequestID].disputeWindowCloses = now + serviceRequestIDs[serviceRequestID].disputeWindow;
        serviceRequestIDs[serviceRequestID].started = true;
    }
    
    function finalizeServiceProvision(uint serviceRequestID){
        if(serviceRequestIDs[serviceRequestID].disputeWindowCloses > now && msg.sender != serviceRequestIDs[serviceRequestID].user ||
        serviceRequestIDs[serviceRequestID].disputed) throw;
        serviceRequestIDs[serviceRequestID].provider.send(serviceRequestIDs[serviceRequestID].cost);
        serviceRequestIDs[serviceRequestID].ended = true;
    }
    
    function withdrawRequest(uint serviceRequestID){
        if(msg.sender != serviceRequestIDs[serviceRequestID].user ||
        serviceRequestIDs[serviceRequestID].started ||
        serviceRequestIDs[serviceRequestID].ended) throw;
        serviceRequestIDs[serviceRequestID].ended = true;
        serviceRequestIDs[serviceRequestID].user.send(serviceRequestIDs[serviceRequestID].cost);
        RequestWithdrawn(serviceRequestID, serviceRequestIDs[serviceRequestID].provider);
    }
    
    function disputeProvision(uint serviceRequestID){
        if(msg.sender != serviceRequestIDs[serviceRequestID].user ||
        serviceRequestIDs[serviceRequestID].ended ||
        !serviceRequestIDs[serviceRequestID].started) throw;
        serviceRequestIDs[serviceRequestID].disputed = true;
        NewDispute(serviceRequestID, serviceRequestIDs[serviceRequestID].arbitrator);
    }
    
    function resolveDispute(uint serviceRequestID, uint finalCostOfService){
        if(msg.sender != serviceRequestIDs[serviceRequestID].arbitrator ||
        !serviceRequestIDs[serviceRequestID].disputed ||
        serviceRequestIDs[serviceRequestID].cost < finalCostOfService) throw;
        serviceRequestIDs[serviceRequestID].provider.send(finalCostOfService);
        serviceRequestIDs[serviceRequestID].user.send(serviceRequestIDs[serviceRequestID].cost - finalCostOfService);
    }
    
    /*
        notes
            costs can be made private if payment is defined in the agreement and occurs off-chain
            a similar contract could be made to repeatedly provide the same service to different users
        
        potential modification to this contract
            list of approved providers, any of which may agree to provide the service
    */
}
