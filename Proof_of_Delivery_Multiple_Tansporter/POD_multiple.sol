pragma solidity ^0.5.17;
import "./Courier.sol";
import "./BT_contract.sol";
contract POD {

    address payable public seller;
    address  payable public buyer;
    address payable public transporter;
    address payable public arbitrator; // Trusted incase of dispute
    address public attestaionAuthority; // Party that attested the smart contract

    uint private keyTr;
    uint private keyBr;

    uint public itemPrice;
    string itemID;

    string public TermsIPFS_Hash; // Terms and conditions agreement IPFS Hash

    // Enum wont allow the contract to be in any other state
    enum contractState { waitingForVerificationbySeller, waitingForVerificationbyTransporter,
                        waitingForVerificationbyBuyer, MoneyWithdrawn, PackageAndTransporterKeyCreated,KeysPassedNextTransporter,
                        ItemOnTheWay,PackageKeyGivenToBuyer, ArrivedToDestination, buyerKeysEntered,
                        PaymentSettledSuccess, DisputeVerificationFailure, EtherWithArbitrator,
                        CancellationRefund, Refund, Aborted }

    contractState public state;

    mapping(address => bytes32) public verificationHash;
    mapping(address => bool) public cancellable;
    

    uint deliveryDuration;
    uint startEntryTransporterKeysBlocktime;
    uint buyerVerificationTimeWindow;
    uint startdeliveryBlocktime;

    constructor(address payable _seller,
    address payable _buyer,
    address payable _transporter,
    address payable _arbitrator,
    address payable _attestationAuthority,
    string memory itemID) public payable {
        seller = _seller;
        buyer = _buyer;
        transporter = _transporter;
        arbitrator = _arbitrator;
        attestaionAuthority = _attestationAuthority;

        itemPrice = 0.001 ether;
        itemID = itemID;
        deliveryDuration = 2 hours; // 2 hours
        buyerVerificationTimeWindow = 2 minutes; // Time for the buyer to verify keys after transporter entered the keys
        TermsIPFS_Hash = "QmWWQSuPMS6aXCbZKpEjPHPUZN2NjB3YrhJTHsV4X3vb2td";

        state = contractState.waitingForVerificationbySeller;
    }

    modifier costs() {
       require(msg.value == 2*itemPrice);
       _;
    }

    modifier OnlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier OnlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier OnlyTransporter() {
        require(msg.sender == transporter);
        _;
    }
    
     

    modifier OnlySeller_Buyer_Transporter() {
        require(msg.sender == seller || msg.sender == buyer || msg.sender == transporter);
        _;
    }

    event TermsAndConditionsSignedBy(string info, address entityAddress);
    event collateralWithdrawnSuccessfully(string info, address entityAddress);
    event PackageCreatedBySeller(string info, address entityAddress);
    event PackageIsOnTheWay(string info, address entityAddress);
    event PackageKeyGivenToBuyer(string info, address entityAddress);
    event ArrivedToDestination(string info, address entityAddress);
    event BuyerEnteredVerificationKeys(string info, address entityAddress);
    event SuccessfulVerification(string info);
    event VerificationFailure(string info);
    event CancellationRequest(address entityAddress, string info, string reason);
    event RefundDueToCancellation(string info);
    event DeliveryTimeExceeded(string info);
    event EtherTransferredToArbitrator(string info, address entityAddress);
    event BuyerExceededVerificationTime(string info, address entityAddress);

    function SignTermsAndConditions() public payable costs OnlySeller_Buyer_Transporter {
        if(msg.sender == seller) {
            require(state == contractState.waitingForVerificationbySeller);
            emit TermsAndConditionsSignedBy("Terms and Conditiond verified : ", msg.sender);
            emit collateralWithdrawnSuccessfully("Double deposit is withdrawn successfully from: ", msg.sender);
            state = contractState.waitingForVerificationbyTransporter;
        }
        else if(msg.sender == transporter) {
            require(state == contractState.waitingForVerificationbyTransporter);
            emit TermsAndConditionsSignedBy("Terms and Conditiond verified : ", msg.sender);
            emit collateralWithdrawnSuccessfully("Double deposit is withdrawn successfully from: ", msg.sender);
            state = contractState.waitingForVerificationbyBuyer;
        }
        else if(msg.sender == buyer) {
            require(state == contractState.waitingForVerificationbyBuyer);
            emit TermsAndConditionsSignedBy("Terms and Conditiond verified : ", msg.sender);
            emit collateralWithdrawnSuccessfully("Double deposit is withdrawn successfully from: ", msg.sender);
            state = contractState.MoneyWithdrawn;
            cancellable[seller] = true;
            cancellable[buyer] = true;
            cancellable[transporter] = true;
        }
    }

    function createPackageAndKey() public payable OnlySeller {
        require(state == contractState.MoneyWithdrawn);

        cancellable[msg.sender] = false;
        cancellable[transporter]=false;
        keyTr = uint(keccak256(
            abi.encodePacked(itemID, transporter, block.timestamp)
        ))/100000000000000000000000000000000000000000000000000000000000000000000000;
        state = contractState.PackageAndTransporterKeyCreated;
        emit PackageCreatedBySeller("Package created and Key given to transporter by the sender ", msg.sender);
}

    // function PassKeytoNextTransporter() public payable OnlyTransporter{
    //     Courier c;
    //     require(state==contractState.PackageAndTransporterKeyCreated);
    //     c.SignTermsAndConditions();
    //     state=contractState.KeysPassedNextTransporter;
        
    // }
    
 
}



