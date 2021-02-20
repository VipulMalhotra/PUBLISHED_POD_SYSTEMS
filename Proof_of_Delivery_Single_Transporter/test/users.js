var Users = artifacts.require('./POD.sol');

contract('Users', async (accounts) => {

  let instance;
  var seller         = null;
  var buyer          = null;
  var transporter    = null;
  var arbitrator =null;
  var attestaionAuthority=null;
  var item_id=null;
  var price=null;
  var collateral=null;



    before(function(){
    
   seller         = accounts[1];
   buyer          = accounts[2];
   transporter    = accounts[3];
   arbitrator =accounts[4];
   attestaionAuthority=accounts[5];
   item_id='1';
   price=0.001;
   collateral=price*2+price*2+price*2;

  });

  before(async () => {
      instance = await Users.new(seller, buyer,transporter ,arbitrator,attestaionAuthority,'1');
  })
  it("should return the list of accounts", async ()=> {
        console.log(accounts);
      });
  it('Contract balance should starts with 0 ETH', async () => {
      let balance = await web3.eth.getBalance(Users.address);
      assert.equal(balance, 0);
  })

  
  it('Contract balance should has 0.002 ETH after deposit from seller', async () => {
    var s=0.002;
  var handleReceipt = (error, receipt) => {
    if (error) console.error(error);
    else {
      console.log(receipt);
      // res.json(receipt);
    }
  }
  
  web3.eth.sendTransaction({
   from: seller,
   to: Users.address,
   value: web3.utils.toWei(s.toString(), "ether")
  }, handleReceipt);
  
});
it('Contract balance should has 0.002 ETH after deposit from buyer', async () => {
  var s=0.002;
var handleReceipt = (error, receipt) => {
  if (error) console.error(error);
  else {
    console.log(receipt);
    // res.json(receipt);
  }
}

web3.eth.sendTransaction({
 from: buyer,
 to: Users.address,
 value: web3.utils.toWei(s.toString(), "ether")
}, handleReceipt);

});

it('Contract balance should has 0.002 ETH after deposit from transporter', async () => {
  var s=0.002;
var handleReceipt = (error, receipt) => {
  if (error) console.error(error);
  else {
    console.log(receipt);
    // res.json(receipt);
  }
}

web3.eth.sendTransaction({
 from: transporter,
 to: Users.address,
 value: web3.utils.toWei(s.toString(), "ether")
}, handleReceipt);

});





it('Contract balance should be 0.006 ETH', async () => {
  let s=0.006;
  let balance = await web3.eth.getBalance(Users.address);
  let seller_balance = await web3.eth.getBalance(accounts[1]);
  assert.equal(balance,web3.utils.toWei(s.toString(), "ether"));
})


it('Create Package with key', async () => {
  let a= instance.createPackageAndKey();
  
  assert.ok(a,'Function_not_called');


})
it('Delivery Package with key', async () => {
  let a= instance.deliverPackage();
  assert.ok(a,'Function not called');


})

// it('Request key by arbitrator', async () => {
//   instance= await Users.new(seller, buyer,{from:transporter} ,arbitrator,attestaionAuthority,'1');
//   let tarns_address=instance.transporter();
//   let a= instance.deliverPackage();
//   assert.equal(tarns_address,transporter);


// })


// it('Verify Transporter', async () => {
//   let a= instance.verifyTransporter(instance.tranporter,instance.seller);
//   assert.ok(a,'Function not called');


// })




    

});
