const HoQuPlatform = artifacts.require("./HoQuPlatform.sol")
const HoQuToken = artifacts.require("./HoQuToken.sol")

const expectThrow = async promise => {
  try {
    await promise
  } catch (error) {
    const invalidJump = error.message.search('invalid JUMP') >= 0
    const invalidOpcode = error.message.search('invalid opcode') >= 0
    const outOfGas = error.message.search('out of gas') >= 0
    assert(invalidJump || invalidOpcode || outOfGas, "Expected throw, got '" + error + "' instead")
    return
  }
  assert.fail('Expected throw not received')
}

contract('HoQuPlatform', function(accounts) {
  it("should have correct input params upon creation", async () => {
    const platform = await HoQuPlatform.deployed()

    const expectedCommission = 5000
    const actualCommission = await platform.commission()

    assert.equal(actualCommission.valueOf(), expectedCommission, "Wrong commission value")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("networks: should correctly add valid network", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://network.test"
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    const result = await platform.getNetwork.call("123")

    assert.equal(result[0], "Test network", "Wrong network name")
    assert.equal(result[1], "http://network.test", "Wrong network url")
    assert.equal(result[2], "1", "Wrong network state")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("networks: should corectly activate existing network when called by system owner", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://network.test"
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", { from: accounts[1] })
    const result = await platform.getNetwork.call("123")

    assert.equal(result[2], "5", "Wrong network state")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("networks: should yell when trying to activate network when calling not from system owner", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://network.test"
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await expectThrow(platform.activateNetwork("123", { from: accounts[9] }))
  })
})

contract('HoQuPlatform', function(accounts) {
  it("offers: should correctly add valid offer", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://network.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", {from: accounts[1]})
    await platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost)
    const result = await platform.getOffer.call("123")

    assert.equal(result[0].valueOf(), "123", "Wrong offer network id")
    assert.equal(result[1].valueOf(), "Test offer", "Wrong offer name")
    assert.equal(result[2].valueOf(), "http://offer.test", "Wrong offer url")
    assert.equal(result[3].valueOf(), web3.toWei("5", "Ether"), "Wrong offer cost")
    assert.equal(result[4].valueOf(), "1", "Wrong offer status")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("offers: should correctly activate existing offer when called by system owner", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", {from: accounts[1]})
    await platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost)
    await platform.activateOffer(offerToAdd.id, {from: accounts[1]})
    const result = await platform.getOffer.call("123")

    assert.equal(result[4].valueOf(), "5", "Wrong offer status")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("offers: should yell when trying to activate offer from wrong account", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", {from: accounts[1]})
    await platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost)
    await expectThrow(platform.activateOffer(offerToAdd.id, {from: accounts[9]}))
  })
})

contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly add valid lead to system", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("5", "Ether")
    }

    const leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", {from: accounts[1]})
    await platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost)
    await platform.activateOffer(offerToAdd.id, {from: accounts[1]})
    await platform.addLead(leadToAdd.id, leadToAdd.offerId, leadToAdd.url, leadToAdd.secret, leadToAdd.meta)
    const result = await platform.getLead.call("123")

    assert.equal(result[0].valueOf(), leadToAdd.offerId, "Wrong lead offer id")
    assert.equal(result[1].valueOf(), leadToAdd.url, "Wrong lead url")
    assert.equal(result[2].valueOf(), leadToAdd.meta, "Wrong lead meta")
    assert.equal(result[3].valueOf(), 0, "Wrong lead inital price")
    assert.equal(result[4].valueOf(), 2, "Wrong lead inital status")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly decline existing lead", async () => {
    const platform = await HoQuPlatform.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: 2
    }

    const leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    }

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url)
    await platform.activateNetwork("123", {from: accounts[1]})
    await platform.addOffer(offerToAdd.id, offerToAdd.networkId, offerToAdd.name, offerToAdd.url, offerToAdd.cost)
    await platform.activateOffer(offerToAdd.id, {from: accounts[1]})
    await platform.addLead(leadToAdd.id, leadToAdd.offerId, leadToAdd.url, leadToAdd.secret, leadToAdd.meta)
    await platform.declineLead(leadToAdd.id)
    const result = await platform.getLead.call("123")

    assert.equal(result[4].valueOf(), 7, "Wrong lead status")
  })
})

contract('HoQuPlatform', function(accounts) {
  it("leads: should correctly approve pending lead", async () => {
    const platform = await HoQuPlatform.deployed()
    const token = await HoQuToken.deployed()

    const networkToAdd = {
      id: "123",
      name: "Test network",
      url: "http://netwrork.test"
    }

    const offerToAdd = {
      id: "123",
      networkId: "123",
      name: "Test offer",
      url: "http://offer.test",
      cost: web3.toWei("7", "Ether") // 7 hqx tokens
    }

    const leadToAdd = {
      id: "123",
      offerId: "123",
      url: "http://test.lead",
      secret: "lead secret",
      meta: ""
    }

    const tokenOwner = accounts[0] // initial supply token owner
    const systemOwner = accounts[1]
    const commissionWallet = accounts[2]
    const networkOwner = accounts[3]
    const offerOwner = accounts[4]
    const leadOwner = accounts[5]

    // transfer some tokens to offer owner in order to pay for lead approval
    await token.transfer(offerOwner, web3.toWei("10", "Ether"), { from: tokenOwner })
    // grant token platform address allowance to perform token transfer
    // on behalf of offer owner
    await token.approve(HoQuPlatform.address, web3.toWei("10", "Ether"), { from: offerOwner })

    await platform.addNetwork(networkToAdd.id, networkToAdd.name, networkToAdd.url, { from: networkOwner })
    await platform.activateNetwork("123", { from: systemOwner })
    await platform.addOffer(
      offerToAdd.id,
      offerToAdd.networkId,
      offerToAdd.name,
      offerToAdd.url,
      offerToAdd.cost,
      { from: offerOwner }
    )
    await platform.activateOffer(offerToAdd.id, { from: systemOwner })
    await platform.addLead(
      leadToAdd.id,
      leadToAdd.offerId,
      leadToAdd.url,
      leadToAdd.secret,
      leadToAdd.meta,
      { from: leadOwner }
    )
    await platform.approveLead(leadToAdd.id, {from:accounts[4]})

    const commissionWalletEndBalance = await token.balanceOf.call(commissionWallet)
    const leadOwnerEndBalance = await token.balanceOf.call(leadOwner)
    const offerOwnerEndBalance = await token.balanceOf.call(offerOwner)
    const systemOwnerEndBalance = await token.balanceOf.call(systemOwner)

    const result = await platform.getLead.call(leadToAdd.id)

    assert.equal(commissionWalletEndBalance.toNumber(), web3.toWei("0.035", "Ether"), "Commission wallet does not hold correct amount")
    assert.equal(leadOwnerEndBalance.toNumber(), web3.toWei("6.965", "Ether"), "Lead owner wallet does not hold correct amount")
    assert.equal(offerOwnerEndBalance.toNumber(), web3.toWei("3", "Ether"), "Offer owner wallet does not hold correct amount")
    assert.equal(systemOwnerEndBalance.toNumber(), 0, "System owner wallet does not hold correct amount")
    assert.equal(result[4].valueOf(), 4, "Wrong lead status")
  })
})