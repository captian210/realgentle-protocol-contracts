const ERC1155Test = artifacts.require("ERC1155Test.sol");
const ZERO = "0x0000000000000000000000000000000000000000";
const { expectThrow } = require("@daonomic/tests-common");
const { sign } = require("./mint");

contract("ERC1155Test", accounts => {
	let testing;
	let royalties;

	beforeEach(async () => {
		testing = await ERC1155Test.new();
		await testing.__ERC1155Test_init();
		royalties = [{ account: accounts[1], value: 1 }, { account: accounts[2], value: 100 }]
	});

	it("should recover signer", async () => {
		const signature = await sign(accounts[1], 1, "testURI", 10, [accounts[1]], royalties, testing.address);
		assert.equal(
			await testing.recover([1, "testURI", 10, [accounts[1]], royalties, [signature]], signature),
			accounts[1]
		);
	});
});
