import assertRevert from 'openzeppelin-solidity/test/helpers/assertRevert';

const ERC20 = artifacts.require('./ERC20Mock.sol');
const LinniaHub = artifacts.require('./LinniaHub.sol');
const LinniaUsers = artifacts.require('./LinniaUsers.sol');
const LinniaRecords = artifacts.require('./LinniaRecords.sol');

const eutil = require('ethereumjs-util');

const testDataContent = '{"foo":"bar","baz":42}';
const testDataHash = eutil.bufferToHex(eutil.sha3(testDataContent));
const testDataUri = 'QmUMqi1rr4Ad1eZ3ctsRUEmqK2U3CyZqpetUe51LB9GiAM';
const testMetadata = 'KEYWORDS';
const testMetaHash = eutil.bufferToHex(eutil.sha3(testMetadata));


contract('LinniaRecords with Reward', accounts => {
  const admin = accounts[0];
  const user = accounts[1];
  const provider1 = accounts[2];
  const provider2 = accounts[3];
  const nonUser = accounts[4];
  let tokenContractAddress;
  let hub;
  let instance;
  let token;

  before('set up a token contract', async () => {
    token = await ERC20.new({from: admin});
    tokenContractAddress = token.address;
    token.unpause({from: admin});
  });
  before('set up a LinniaHub contract', async () => {
    hub = await LinniaHub.new({from: admin});
    token.transfer(hub.address, 100, {from: admin});
  });
  before('set up a LinniaUsers contract', async () => {
    const usersInstance = await LinniaUsers.new(hub.address);
    await hub.setUsersContract(usersInstance.address);
    usersInstance.register({from: user});
    usersInstance.register({from: provider1});
    usersInstance.register({from: provider2});
    usersInstance.setProvenance(provider1, 1);
    usersInstance.setProvenance(provider2, 2);
  });
  beforeEach('deploy a new LinniaRecords contract', async () => {
    instance = await LinniaRecords.new(hub.address);
    await hub.setRecordsContract(instance.address);
  });
  describe('add record by user and receive LIN tokens', () => {
    it('should allow a user to add a new record and receive LIN tokens', async () => {
      const tx = await instance.addRecordwithReward(
        testDataHash,
        testMetadata,
        testDataUri,
        tokenContractAddress,
        {from: user}
      );
      assert.equal(tx.logs.length, 2);

      assert.equal(tx.logs[1].event, 'LinniaReward');

      assert.equal(tx.logs[0].event, 'LinniaRecordAdded');
      assert.equal(tx.logs[0].args.dataHash, testDataHash);
      assert.equal(tx.logs[0].args.owner, user);
      assert.equal(tx.logs[0].args.metadata, testMetadata);
      const {timestamp} = web3.eth.getBlock(tx.receipt.blockNumber);
      // check state
      const storedRecord = await instance.records(testDataHash);
      assert.equal(storedRecord[0], user);
      assert.equal(storedRecord[1], testMetaHash);
      assert.equal(storedRecord[2], 0); // sig count
      assert.equal(storedRecord[3], 0); // iris score
      assert.equal(storedRecord[4], testDataUri);
      assert.equal(storedRecord[5], timestamp);
    });
    it('should not allow user to add same record twice', async () => {
      await instance.addRecord(
        testDataHash,
        testMetadata,
        testDataUri, {
          from: user
        });
      // try submitting the file again
      await assertRevert(
        instance.addRecordwithReward(
          testDataHash,
          testMetadata,
          testDataUri,
          tokenContractAddress, {
            from: user
          })
      );
    });
    it('should not allow non-users to call', async () => {
      await assertRevert(
        instance.addRecordwithReward(
          testDataHash,
          testMetadata,
          testDataUri,
          tokenContractAddress, {
            from: nonUser
          })
      );
    });
    it('should reject if data hash or data uri is zero', async () => {
      // try zero data hash
      await assertRevert(
        instance.addRecordwithReward(
          0,
          testMetadata,
          testDataUri,
          tokenContractAddress, {
            from: user
          })
      );
      // try zero data uri
      await assertRevert(
        instance.addRecordwithReward(
          testDataHash,
          testMetadata,
          0,
          tokenContractAddress, {
            from: user
          })
      );
    });
  });
  describe('pausable', () => {
    it('should not allow adding records for reward when paused by admin', async () => {
      const tx = await instance.pause();
      assert.equal(tx.logs[0].event, 'Pause');
      await assertRevert(
        instance.addRecordwithReward(
          testDataHash,
          testMetadata,
          testDataUri,
          tokenContractAddress, {
            from: user
          })
      );
      const tx2 = await instance.unpause();
      assert.equal(tx2.logs[0].event, 'Unpause');
      const tx3 = await instance.addRecordwithReward(
        testDataHash,
        testMetadata,
        testDataUri,
        tokenContractAddress,
        {from: user}
      );
      assert.equal(tx3.logs[0].event, 'LinniaRecordAdded');
    });
  });
});
