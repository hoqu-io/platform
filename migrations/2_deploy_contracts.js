var HoQuToken = artifacts.require("./HoQuToken.sol");
var HoQuPlatformConfig = artifacts.require("./HoQuPlatformConfig.sol");
var HoQuPlatform = artifacts.require("./HoQuPlatform.sol");

module.exports = function(deployer, network, accounts) {
  if (network === 'development') {
    var totalSupply = web3.toWei("1000", "Ether"); // 1000 hqx tokens
    var commission = 5000; // in szabo = 0.005 eth = 5000 szabo = 0.5%
    var systemOwner = web3.eth.accounts[1];
    var commissionWallet = web3.eth.accounts[2];

    deployer.deploy(HoQuToken, totalSupply).then(function () {
      return deployer.deploy(HoQuPlatformConfig, systemOwner, commissionWallet)
    }).then(function () {
      return deployer.deploy(HoQuPlatform, HoQuPlatformConfig.address, HoQuToken.address, commission);
    });
  } else {
    // production
  }
};
