var HoQuPlatform = artifacts.require("./HoQuPlatform.sol");
var HoQuToken = artifacts.require("./HoQuToken.sol");

contract('HoQuPlatform', function(accounts) {
  it("should have correct input params upon creation", function() {
    var platform;

    var expectedCommission = 5000;
    var actualCommission;

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.commission();
    }).then(function (commission) {
      actualCommission = commission;
      assert.equal(actualCommission.valueOf(), expectedCommission, "Wrong commission value");
    });
  });
});
contract('HoQuPlatform', function(accounts) {
  it("networks: should correctly add valid network", function () {
    var platform;

    var networkToAdd = {
      id: "12345",
      name: "Test name",
      url: "http://netwrork.test"
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.getNetwork.call("12345");
    }).then(function (result) {
      assert.equal(result[0], "Test name", "Wrong netwrok name")
      assert.equal(result[1], "http://netwrork.test", "Wrong network url")
      assert.equal(result[2], "1", "Wrong network state")
    });
  });
});
contract('HoQuPlatform', function(accounts) {
  it("networks: should corectly activate existing network when called by system owner", function () {
    var platform;

    var networkToAdd = {
      id: "123456",
      name: "Test name",
      url: "http://netwrork.test"
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123456", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.getNetwork.call("123456");
    }).then(function (result) {
      assert.equal(result[2], "5", "Wrong network state");
    });
  });
});
contract('HoQuPlatform', function(accounts) {
  it("networks: should yell when trying to activate network when calling not from system owner", function () {
    var platform;

    var networkToAdd = {
      id: "1234567",
      name: "Test name",
      url: "http://netwrork.test"
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("1234567", {from: accounts[9]});
    }).then(function () {
      assert.fail("Expected call to throw but it didn't.");
    }).catch(function (error) {
      assert.isTrue(error.message.search('invalid opcode') >= 0, 'Expected invalid opcode throw, but got another one');
    })
  });
});
contract('HoQuPlatform', function(accounts) {
  it("offers: should correctly add valid offer", function () {
    var platform;

    var networkToAdd = {
      id: "123456789",
      name: "Test name",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123456789",
      name: "Test offer",
      url: "http://offer.test",
      cost: 2
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123456789", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost);
    }).then(function (tHash) {
      return platform.getOffer.call("123");
    }).then(function (result) {
      assert.equal(result[0].valueOf(), "123456789", "Wrong offer network id")
      assert.equal(result[1].valueOf(), "Test offer", "Wrong offer name")
      assert.equal(result[2].valueOf(), "http://offer.test", "Wrong offer url")
      assert.equal(result[3].valueOf(), "2", "Wrong offer cost")
      assert.equal(result[4].valueOf(), "1", "Wrong offer status")
    });
  })
});
contract('HoQuPlatform', function(accounts) {
  it("offers: should correctly activate existing offer when called by system owner", function () {
    var platform;

    var networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost);
    }).then(function (tHash) {
      return platform.activateOffer(offerToAdd.id, {from: accounts[1]});
    }).then(function (tHash) {
      return platform.getOffer.call("123");
    }).then(function (result) {
      assert.equal(result[4].valueOf(), "5", "Wrong offer status")
    });
  })
});
contract('HoQuPlatform', function(accounts) {
  it("offers: should yell when trying to activate offer from wrong account", function () {
    var platform;

    var networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost);
    }).then(function (tHash) {
      return platform.activateOffer(offerToAdd.id, {from: accounts[9]});
    }).then(function () {
      assert.fail("Expected call to throw but it didn't.");
    }).catch(function (error) {
      assert.isTrue(error.message.search('invalid opcode') >= 0, 'Expected invalid opcode throw, but got another one');
    });
  });
});
contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly add valid lead to system", function () {
    var platform;

    var networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: 2
    };

    var leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost);
    }).then(function (tHash) {
      return platform.activateOffer(offerToAdd.id, {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addLead(leadToAdd.id, leadToAdd.offerId, leadToAdd.url, leadToAdd.secret, leadToAdd.meta)
    }).then(function (tHash) {
      return platform.getLead.call("123");
    }).then(function (result) {
      assert.equal(result[0].valueOf(), leadToAdd.offerId, "Wrong lead offer id");
      assert.equal(result[1].valueOf(), leadToAdd.url, "Wrong lead url");
      assert.equal(result[2].valueOf(), leadToAdd.meta, "Wrong lead meta");
      assert.equal(result[3].valueOf(), 0, "Wrong lead inital price");
      assert.equal(result[4].valueOf(), 2, "Wrong lead inital status");
    });
  })
});
contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly decline existing lead", function () {
    var platform;

    var networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: 2
    };

    var leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    };

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url);
    }).then(function (tHash) {
      return platform.activateNetwork("123", {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost);
    }).then(function (tHash) {
      return platform.activateOffer(offerToAdd.id, {from: accounts[1]});
    }).then(function (tHash) {
      return platform.addLead(leadToAdd.id, leadToAdd.offerId, leadToAdd.url, leadToAdd.secret, leadToAdd.meta)
    }).then(function (tHash) {
      return platform.declineLead(leadToAdd.id);
    }).then(function (tHash) {
      return platform.getLead.call("123");
    }).then(function (result) {
      assert.equal(result[4].valueOf(), 7, "Wrong lead status");
    });
  })
});
contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly approve pending lead", function () {
    var platform;
    var token;

    var networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    };

    var offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("7", "Ether") // 7 hqx tokens
    };

    var leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    };

    var tokenOwner = accounts[0]; // initial supply token owner
    var systemOwner = accounts[1];
    var commissionWallet = accounts[2];
    var networkOwner = accounts[3];
    var offerOwner = accounts[4];
    var leadOwner = accounts[5];

    var commissionWalletStartBalance;
    var commissionWalletEndBalance;
    var leadOwnerStartBalance;
    var leadOwnerEndBalance;
    var offerOwnerStartBalance;
    var offerOwnerEndBalance;
    var systemOwnerStartBalance;
    var systemOwnerEndBalance;

    HoQuToken.deployed().then(function (instance) {
      token = instance;
      // transfer some tokens to offer owner in order to pay for lead approval
      return token.transfer(offerOwner, web3.toWei("10", "Ether"), { from: tokenOwner });
    }).then(function (tHash) {
      // HoQuPlatform.address - this.address
      // accounts[9] third party account

      // grant token platform address allowance to perform token transfer
      // on behalf of offer owner
      return token.approve(HoQuPlatform.address, web3.toWei("10", "Ether"), { from: offerOwner });
    });

    return HoQuPlatform.deployed().then(function (instance) {
      platform = instance;
      return platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url, { from: networkOwner });
    }).then(function (tHash) {
      return platform.activateNetwork("123", { from: systemOwner });
    }).then(function (tHash) {
      return platform.addOffer(
        offerToAdd.id,
        offerToAdd.networkId,
        offerToAdd.name,
        offerToAdd.url,
        offerToAdd.cost,
        { from: offerOwner }
      );
    }).then(function (tHash) {
      return platform.activateOffer(offerToAdd.id, { from: systemOwner });
    }).then(function (tHash) {
      return platform.addLead(
        leadToAdd.id,
        leadToAdd.offerId,
        leadToAdd.url,
        leadToAdd.secret,
        leadToAdd.meta,
        { from: leadOwner }
      );
    }).then(function (tHash) {
      return platform.approveLead(leadToAdd.id, {from:accounts[4]});
    }).then(function (tHash) {
      return token.balanceOf.call(commissionWallet);
    }).then(function (result) {
      commissionWalletEndBalance = result.toNumber();
      return token.balanceOf.call(leadOwner);
    }).then(function (result) {
      leadOwnerEndBalance = result.toNumber();
      return token.balanceOf.call(offerOwner);
    }).then(function (result) {
      offerOwnerEndBalance = result.toNumber();
      return token.balanceOf.call(systemOwner);
    }).then(function (result) {
      systemOwnerEndBalance = result.toNumber();
      return platform.getLead.call(leadToAdd.id);
    }).then(function (result) {
      assert.equal(commissionWalletEndBalance, web3.toWei("0.035", "Ether"), "Commission wallet does not hold correct amount");
      assert.equal(leadOwnerEndBalance, web3.toWei("6.965", "Ether"), "Lead owner wallet does not hold correct amount");
      assert.equal(offerOwnerEndBalance, web3.toWei("3", "Ether"), "Offer owner wallet does not hold correct amount");
      assert.equal(systemOwnerEndBalance, 0, "System owner wallet does not hold correct amount");
      assert.equal(result[4].valueOf(), 4, "Wrong lead status");
    });
  })
});