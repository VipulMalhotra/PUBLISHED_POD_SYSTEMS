pragma solidity ^0.5.17;


contract BT_contract {
    
    address payable public transporter;
    address payable public buyer;
  
    address payable public arbitrator;
    address payable public seller;
   
    
    uint private keyTr;
    uint private keyBr;

    uint public itemPrice;
    string itemID;

    string public TermsIPFS_Hash; // Terms and conditions agreement IPFS Hash

    // Enum wont allow the contract to be in any other state
    enum contractState { waitingItemReceived,PackageReceivedByBuyer,ArrivedToDestination,
                         KeysEntered,KeysVerified,PaymentSettledTransferedtoBT,PaymentSettledSuccess,DisputeVerificationFailure, EtherWithArbitrator,
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
    address payable _buyer,
    address payable _seller,
    address payable _arbitrator,
    string memory _itemID) public payable {
        
        transporter = _transporter;
        buyer = _buyer;
       seller=_seller;
       arbitrator=_arbitrator;

        itemPrice = 1 ether;
        itemID = _itemID;
        deliveryDuration = 2 hours; // 2 hours
        buyerVerificationTimeWindow = 2 minutes; // Time for the buyer to verify keys after transporter entered the keys
        TermsIPFS_Hash = "QmWWQSuPMS6aXCbZKpEjPHPUZN2NjB3YrhJTHsV4X3vb2td";
        state = contractState.waitingItemReceived;
    }

    modifier costs() {
       require(msg.value == 2*itemPrice);
       _;
    }
    modifier OnlyTransporter() {
        require(msg.sender == transporter);
        _;
    }


    modifier OnlyBuyer() {
        require(msg.sender == buyer);
        _;
    }
    

    event TermsAndConditionsSignedBy(string info, address entityAddress);
    event collateralWithdrawnSuccessfully(string info, address entityAddress);
    event PackageKeyGivenToNextTransporter(string info, address entityAddress);
    event ArrivedToDestination(string info, address entityAddress);
    event BuyerEnteredVerificationKeys(string info, address entityAddress);
    event SuccessfulVerification(string info);
    event VerificationFailure(string info);
    // event CancellationRequest(address entityAddress, string info, string reason);
    // event RefundDueToCancellation(string info);
    // event DeliveryTimeExceeded(string info);
    event EtherTransferredToArbitrator(string info, address entityAddress);
    event NextTransporterExceededVerificationTime(string info, address entityAddress);
    event Success(string info, address entityAddress);
    event PaymentSettledSuccess(string info,address entityAddress);
    event deposit_from_Courier_contract(string info, address entityAddress);
    
    
    function ConfirmPackageReceived() public OnlyBuyer {
        require(state == contractState.waitingItemReceived);
        startdeliveryBlocktime = block.timestamp;//save the delivery time
        emit PackageKeyGivenToNextTransporter("The package reached destination", msg.sender);
        state = contractState.PackageReceivedByBuyer;
    }
    
    function KeysEnteredByTransporter(string memory keyT, string memory keyR) public OnlyTransporter {
        require(state == contractState.PackageReceivedByBuyer);
        emit ArrivedToDestination("Transporter Arrived To Destination and entered keys " , msg.sender);
        verificationHash[transporter] = keccak256(
                abi.encodePacked(keyT, keyR)
            );
        state = contractState.ArrivedToDestination;
        startEntryTransporterKeysBlocktime = block.timestamp;
    }
    
    function verifyKeysByBuyer(string memory keyT, string memory keyR) public OnlyBuyer{
        require(state == contractState.ArrivedToDestination);
        emit BuyerEnteredVerificationKeys("Reciever entered keys, waiting for payment settlement", msg.sender);
        verificationHash[buyer] = keccak256(
                abi.encodePacked(keyT, keyR)
            );
        state = contractState.KeysEntered;
        verification();
    }
    

    function verification() internal {
        require(state == contractState.KeysEntered);
        if(verificationHash[transporter] == verificationHash[buyer]){
            emit SuccessfulVerification("Payment will shortly be settled , successful verification!");
            state = contractState.KeysVerified;
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
    function transfer_balance_from_Courier() public payable{
        emit deposit_from_Courier_contract('Balance transfered from Courier Contract Recieved',msg.sender);
        
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function settle_payement() public payable{
        
        buyer.transfer(itemPrice);
        seller.transfer(address(this).balance);
        emit PaymentSettledSuccess('Payment Settled Successfully ',msg.sender);
        state=contractState.PaymentSettledSuccess;
    }
    
      
    }
    
        
        

