'use strict';
var POD = artifacts.require('./POD.sol');
module.exports = function(deployer, network, accounts){
 deployer.deploy(POD, accounts[1],accounts[2],accounts[3],accounts[4],accounts[5],'1');
};