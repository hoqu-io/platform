var HoQuToken = artifacts.require("./HoQuToken.sol");

var expectedTotalSupply = web3.toWei("1000", "Ether"); // hqx

contract('HoQuToken', function(accounts) {
  it("should have correct total supply set", function () {
    return HoQuToken.deployed().then(function (instance) {
      return instance.totalSupply();
    }).then(function(totalSupply) {
      assert.equal(totalSupply.valueOf(), web3.toBigNumber(expectedTotalSupply), "Wrong total supply");
    })
  });
  it("should move all of initial supply to owner", function() {
    return HoQuToken.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), web3.toBigNumber(expectedTotalSupply), "Owner has wrong balance");
    });
  });
  it("should have correct token meta info", function() {
    var token;

    var expectedName = "HOQU Token";
    var expectedSymbol = "HQX";
    var expectedDecimals = 18;

    var actualName;
    var actualSymbol;
    var actualDecimals;

    return HoQuToken.deployed().then(function(instance) {
      token = instance;
      return token.name();
    }).then(function (name) {
      actualName = name;
      return token.symbol();
    }).then(function (symbol) {
      actualSymbol = symbol;
      return token.decimals();
    }).then(function (decimals) {
      actualDecimals = decimals;

      assert.equal(actualName.valueOf(), expectedName, "Wrong token name");
      assert.equal(actualSymbol.valueOf(), expectedSymbol, "Wrong token symbol");
      assert.equal(actualDecimals.valueOf(), expectedDecimals, "Wrong decimals value");
    });
  })
});