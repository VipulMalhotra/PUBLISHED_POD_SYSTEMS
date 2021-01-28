pragma solidity ^0.5.17;

contract Courier {
    
    address payable public transporter;
    address payable public transporter2;
    address  payable public arbitrator; 
    
    uint private keyTr;
    uint private keyBr;

    uint public itemPrice;
    string itemID;

    string public TermsIPFS_Hash; // Terms and conditions agreement IPFS Hash

    // Enum wont allow the contract to be in any other state
    enum contractState { waitingForVerificationbyTransporter,
                         MoneyWithdrawn, PackageReceivedByTansporter,ArrivedToDestination,
                         KeysEntered,PassedToNextTransporter,DisputeVerificationFailure, EtherWithArbitrator,
                        CancellationRefund, Refund, Aborted }

    contractState public state;
    
     mapping(address => bytes32) public verificationHash;
    mapping(address => bool) public cancellable;

    uint deliveryDuration;
    uint startEntryTransporterKeysBlocktime;
    uint buyerVerificationTimeWindow;
    uint startdeliveryBlocktime;

    constructor(
    address payable _transporter,
    address payable _transporter2,
    address payable _arbitrator,
    string memory itemID) public payable {
        
        transporter = _transporter;
        transporter2 = _transporter2;
        arbitrator = _arbitrator;

        itemPrice = 0.001 ether;
        itemID = itemID;
        deliveryDuration = 2 hours; // 2 hours
        buyerVerificationTimeWindow = 2 minutes; // Time for the buyer to verify keys after transporter entered the keys
        TermsIPFS_Hash = "QmWWQSuPMS6aXCbZKpEjPHPUZN2NjB3YrhJTHsV4X3vb2td";
        state = contractState.waitingForVerificationbyTransporter;
    }

    modifier costs() {
       require(msg.value == 2*itemPrice);
       _;
    }
    modifier OnlyTransporter() {
        require(msg.sender == transporter);
        _;
    }


    modifier OnlyNextTransporter() {
        require(msg.sender == transporter2);
        _;
    }
    

    event TermsAndConditionsSignedBy(string info, address entityAddress);
    event collateralWithdrawnSuccessfully(string info, address entityAddress);
    event PackageKeyGivenToNextTransporter(string info, address entityAddress);
    event ArrivedToDestination(string info, address entityAddress);
    event BuyerEnteredVerificationKeys(string info, address entityAddress);
    event SuccessfulVerification(string info);
    event VerificationFailure(string info);
    event CancellationRequest(address entityAddress, string info, string reason);
    event RefundDueToCancellation(string info);
    event DeliveryTimeExceeded(string info);
    event EtherTransferredToArbitrator(string info, address entityAddress);
    event NextTransporterExceededVerificationTime(string info, address entityAddress);

    function SignTermsAndConditions() public payable costs OnlyNextTransporter {
        
        if(msg.sender == transporter2) {
            require(state == contractState.waitingForVerificationbyTransporter);
            emit TermsAndConditionsSignedBy("Terms and Conditiond verified : ", msg.sender);
            emit collateralWithdrawnSuccessfully("Double deposit is withdrawn successfully from: ", msg.sender);
            state = contractState.MoneyWithdrawn;
        }
        
    }
    function ConfirmPackageReceived() public OnlyNextTransporter {
        require(state == contractState.MoneyWithdrawn);
        startdeliveryBlocktime = block.timestamp;//save the delivery time
        emit PackageKeyGivenToNextTransporter("The package is being delivered and the key is received by the Transporter", msg.sender);
        state = contractState.PackageReceivedByTansporter;
    }
    function KeysEnteredByTransporter(string memory keyT, string memory keyR) public OnlyTransporter {
        require(state == contractState.PackageReceivedByTansporter);
        emit ArrivedToDestination("Transporter Arrived To Destination and entered keys " , msg.sender);
        verificationHash[transporter] = keccak256(
                abi.encodePacked(keyT, keyR)
            );
        state = contractState.ArrivedToDestination;
        startEntryTransporterKeysBlocktime = block.timestamp;
    }
    
    function verifyKeyNextTransporter(string memory keyT, string memory keyR) public OnlyNextTransporter {
        require(state == contractState.ArrivedToDestination);
        emit BuyerEnteredVerificationKeys("Reciever entered keys, waiting for payment settlement", msg.sender);
        verificationHash[transporter2] = keccak256(
                abi.encodePacked(keyT, keyR)
            );
        state = contractState.KeysEntered;
        verification();
    }
    
    
    
    
    function verification() internal {
        require(state == contractState.KeysEntered);
        if(verificationHash[transporter] == verificationHash[transporter2]){
            emit SuccessfulVerification("Transporter and Next Transporter Keys Verified!");
            state = contractState.PassedToNextTransporter;
        }
        else {
            //trusted entity the Arbitrator resolves the issue
            emit VerificationFailure("Verification failed , keys do not match. Please solve the dispute off chain. No refunds.");
            state = contractState.DisputeVerificationFailure;
            arbitrator.transfer(address(this).balance);//all ether with the contract
            state = contractState.EtherWithArbitrator;
            emit EtherTransferredToArbitrator("Due to dispute all Ether deposits have been transferred to arbitrator ", arbitrator);
            state = contractState.Aborted;
        }
    }



}