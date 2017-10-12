const HoQuPlatformConfig = artifacts.require("./HoQuPlatformConfig.sol");

contract('HoQuPlatformConfig', function(accounts) {
  it("should have correct wallet addresses", async () => {
    const expectedSystemOwner = accounts[1];
    const expectedCommissionWallet = accounts[2];

    const config = await HoQuPlatformConfig.deployed();

    const actualSystemOwner = await config.systemOwner();
    const actualCommissionWallet = await config.commissionWallet();

    assert.equal(actualSystemOwner, expectedSystemOwner, "Incorrect system owner");
    assert.equal(actualCommissionWallet, expectedCommissionWallet, "Incorrect commission wallet");
  })
});
