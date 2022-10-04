const assert = require("assert");
const { AsyncLocalStorage } = require("async_hooks");
const ganache = require("ganache");
const Web3 = require("web3");
const web3 = new Web3(ganache.provider());

const contractABI = require("../web3/toonverseABI.json");
const contractByteCode = require("../web3/toonverseByteCode.json");

let ACCOUNTS;
let OWNER_ACCOUNT;
let DEV_ACCOUNT = "0x3883552f0eDC54731623952c37e6cdbC2b7eaF36"
let USER1_ACCOUNT;
let TOONVERSE_CONTRACT;
let PRICE;
let PRICE_IN_WEI =38000000000000000;
let MAX_MINT_AMOUNT = 20;
let MAX_NFT_SUPPLY = 6666;
let INITIAL_OWNER_MINTS = 100;
let INITIAL_DEV_MINTS = 25;
let INITIAL_PARTNER_MINTS = 100;



// beforeEach(async () => {
// });

describe("Toonverse initialization logic.", async () => {
  it("Contract Initialization Tests.", async () => {
    ACCOUNTS = await web3.eth.getAccounts();
    OWNER_ACCOUNT = ACCOUNTS[0];
    USER1_ACCOUNT = ACCOUNTS[1];
    TOONVERSE_CONTRACT = await new web3.eth.Contract(contractABI)
      .deploy({ data: contractByteCode.object })
      .send({ from: OWNER_ACCOUNT, gas: "20000000" });
    assert.ok(TOONVERSE_CONTRACT.options.address);
  });

  it("Name is Toonverse, Symbol is TOON, maxMintAmount is 20, Maxsupply 6666.", async () => {
    assert.equal("Toonverse", await TOONVERSE_CONTRACT.methods.name().call());
    assert.equal("TOON", await TOONVERSE_CONTRACT.methods.symbol().call());
    assert.equal(MAX_MINT_AMOUNT, await TOONVERSE_CONTRACT.methods.MAX_MINT_AMOUNT().call());
    assert.equal(MAX_NFT_SUPPLY, await TOONVERSE_CONTRACT.methods.MAX_SUPPLY().call());
  });

  it("Number in circulation is 1 initially,Cost is .038", async () => {
    assert.equal(175, await TOONVERSE_CONTRACT.methods.totalSupply().call());
    assert.equal(
      PRICE_IN_WEI,
      await TOONVERSE_CONTRACT.methods.COST().call()
    );
  });

  it("Contract has owner and users,baseURI and notRevealedURI.", async () => {
    assert.equal(
      OWNER_ACCOUNT,
      await TOONVERSE_CONTRACT.methods.OWNER().call()
    );
    assert.notEqual(
      USER1_ACCOUNT,
      await TOONVERSE_CONTRACT.methods.OWNER().call()
    );
    assert.ok(await TOONVERSE_CONTRACT.methods.BASE_URI().call());
    assert.ok(await TOONVERSE_CONTRACT.methods.NOT_REVEALED_URI().call());
  });

  it("Contract is paused, Not revealed, and whitelist only.", async () => {
    assert.equal(true, await TOONVERSE_CONTRACT.methods.PAUSED().call());
    assert.equal(false, await TOONVERSE_CONTRACT.methods.REVEALED().call());
    assert.equal(true, await TOONVERSE_CONTRACT.methods.IS_WHITELIST_ONLY().call());
  });

  it("Merkleroot has an entry, not revealed URI has entry.", async () => {
    assert.ok(await TOONVERSE_CONTRACT.methods.WHITELIST_MERKLE_ROOT().call());
    assert.ok(await TOONVERSE_CONTRACT.methods.NOT_REVEALED_URI().call());
  });

  it("Only Owner Can setWhiteListMerkleRoot.", async () => {
    let setWhiteListMerkleRoot = true;
    try {
      await TOONVERSE_CONTRACT.methods
        .setWhiteListMerkleRoot(
          "0xd4e5bd371dfbeece6f828705d5ba966c3f742b6f4429e7cf08f1b2248f7349a8"
        )
        .send({
          from: USER1_ACCOUNT,
        });
    } catch (error) {
      setWhiteListMerkleRoot = false;
    }
    assert.equal(false, setWhiteListMerkleRoot);
  });

  it("Only Owner Can setPaused.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.setPaused(false).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setBaseExtension.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.setBaseExtension("xml").send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setBaseURI.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods
        .setBaseURI("http://thisisatest.com/")
        .send({
          from: USER1_ACCOUNT,
        });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setNotRevealedURI.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods
        .setNotRevealedURI("http://thisisatest.com/1.json")
        .send({
          from: USER1_ACCOUNT,
        });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setCost.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.setCost(600).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setRevealed.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.setRevealed(true).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("Only Owner Can setWhiteListOnly.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.setWhiteListOnly(false).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });
});

describe("Toonverse Minting Logic. ", async () => {
  it("Owner can mint for free and with whitelist when contract is paused.", async () => {
    await TOONVERSE_CONTRACT.methods.mint(2).send({
      from: OWNER_ACCOUNT,
    });
    let numOwned = await TOONVERSE_CONTRACT.methods
      .balanceOf(OWNER_ACCOUNT)
      .call();
    assert.equal(INITIAL_OWNER_MINTS + 2, numOwned);
    for (let i = 0; i < INITIAL_OWNER_MINTS; i++) {
      assert.equal(
        i,
        await TOONVERSE_CONTRACT.methods
          .tokenOfOwnerByIndex(OWNER_ACCOUNT, i)
          .call()
      );
    }

    await TOONVERSE_CONTRACT.methods
      .mintWhiteList(
        [
          "0xbf61c7604b988bb3009b612960655930456757d79f99487e2d3f19fd8642cdc5",
          "0xde59b7738d662c1c7408753bb673b986582a77fe1d06bc57154ce73876a76229",
        ],
        2
      )
      .send({
        from: OWNER_ACCOUNT,
      });

    for (
      let i = 2;
      i < (await TOONVERSE_CONTRACT.methods.balanceOf(OWNER_ACCOUNT).call()-INITIAL_DEV_MINTS - INITIAL_PARTNER_MINTS);
      i++
    ) {
      assert.equal(
        i  ,
        await TOONVERSE_CONTRACT.methods
          .tokenOfOwnerByIndex(OWNER_ACCOUNT, i)
          .call()
      );
    }
  });

  it("Normal use CANT mint or whitelistmint while contract is paused.", async () => {
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.mint(2).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);

    bool = true;
    try {
      await TOONVERSE_CONTRACT.methods
        .mintWhiteList(
          [
            "0xbf61c7604b988bb3009b612960655930456757d79f99487e2d3f19fd8642cdc5",
            "0xde59b7738d662c1c7408753bb673b986582a77fe1d06bc57154ce73876a76229",
          ],
          2
        )
        .send({
          from: USER1_ACCOUNT,
        });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
  });

  it("URI for token URI (1) is not revealedURI", async () => {
    assert.equal(
      await TOONVERSE_CONTRACT.methods.tokenURI(1).call(),
      await TOONVERSE_CONTRACT.methods.NOT_REVEALED_URI().call()
    );
  });

  //TODO: refactor this into two methods.
  //OWner unpauses contract and whitelister gets merklie API response and mints with money.
  //user1 can mint with money after whitelist is off.
  it("Owner can unpause and set whitelist only to false and normal user can mint only with sending money after.", async () => {
    //Set paused and whitelist only to false.
    await TOONVERSE_CONTRACT.methods.setPaused(false).send({
      from: OWNER_ACCOUNT,
    });
    assert.equal(false, await TOONVERSE_CONTRACT.methods.PAUSED().call());
    await TOONVERSE_CONTRACT.methods.setWhiteListOnly(false).send({
      from: OWNER_ACCOUNT,
    });
    assert.equal(
      false,
      await TOONVERSE_CONTRACT.methods.IS_WHITELIST_ONLY().call()
    );

    //verify normal user starts with 0 nfts and then mints with 2 only when sending price.
    assert.equal(
      0,
      await TOONVERSE_CONTRACT.methods.balanceOf(USER1_ACCOUNT).call()
    );

    //verify can not mint with out sending money
    bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.mint(2).send({
        from: USER1_ACCOUNT,
        //Would save value: right here if it WERE sending money.
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);

    //verify can  mint when sending money
    PRICE = await TOONVERSE_CONTRACT.methods.COST().call();
    await TOONVERSE_CONTRACT.methods.mint(2).send({
      from: USER1_ACCOUNT,
      value: PRICE * 2,
    });
    assert.equal(
      2,
      await TOONVERSE_CONTRACT.methods.balanceOf(USER1_ACCOUNT).call()
    );
  });

  it("Account has balance of 2 sales.", async () => {
    assert.equal(
      PRICE * 2,
      await web3.eth.getBalance(TOONVERSE_CONTRACT.options.address)
    );
  });

  it("Only Owner Can withdraw.", async () => {
    let currentContractBalance = await web3.eth.getBalance(
      TOONVERSE_CONTRACT.options.address
    );
    assert.equal(PRICE * 2, currentContractBalance);
    //First verify normal user CANT withdraw.
    let bool = true;
    try {
      await TOONVERSE_CONTRACT.methods.withdraw(600).send({
        from: USER1_ACCOUNT,
      });
    } catch (error) {
      bool = false;
    }
    assert.equal(false, bool);
    //Second get owners balance and verify they can withdraw.
    assert.equal(PRICE * 2, currentContractBalance);
    let origAdminsBalance = await web3.eth.getBalance(OWNER_ACCOUNT);
    await TOONVERSE_CONTRACT.methods.withdraw(BigInt(PRICE * 2)).send({
      from: OWNER_ACCOUNT,
    });

    assert(
      BigInt(origAdminsBalance) <
        BigInt(await web3.eth.getBalance(OWNER_ACCOUNT))
    );
    assert(
      BigInt(currentContractBalance) >
        BigInt(await web3.eth.getBalance(TOONVERSE_CONTRACT.options.address))
    );
    assert.equal(
      0,
      await web3.eth.getBalance(TOONVERSE_CONTRACT.options.address)
    );
  });
});


//TESTS to still be written.
//Can white list user mint?