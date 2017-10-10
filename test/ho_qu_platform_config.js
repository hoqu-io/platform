var HoQuPlatformConfig = artifacts.require("./HoQuPlatformConfig.sol");

contract('HoQuPlatformConfig', function(accounts) {
  it("should have correct wallet addresses", function () {
    var config;

    var expectedSystemOwner = accounts[1];
    var expectedCommissionWallet = accounts[2];

    var actualSystemOwner;
    var actualCommissionWallet;

    return HoQuPlatformConfig.deployed().then(function (instance) {
      config = instance;
      return config.systemOwner();
    }).then(function(systemOwner) {
      actualSystemOwner = systemOwner;
      return config.commissionWallet();
    }).then(function (commissionWallet) {
      actualCommissionWallet = commissionWallet;

      assert.equal(actualSystemOwner, expectedSystemOwner, "Incorrect system owner");
      assert.equal(actualCommissionWallet, expectedCommissionWallet, "Incorrect commission wallet");
    });
  })
});
