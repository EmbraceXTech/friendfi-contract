// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FriendKeyManager.sol";
import "./contracts/TestFunctionsRouter.sol";
import "./contracts/TestVRFCoordinator.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {FunctionsResponse} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol";

contract FriendKeyManagerTest is Test {

    FriendKeyManager public manager;
    TestFunctionsRouter public functionRouter;
    TestVRFCoordinator public vrfCoordinator;

    function setUp() public {
        uint64 subscriptionId = 4070;
        functionRouter = new TestFunctionsRouter();
        vrfCoordinator = new TestVRFCoordinator();

        string[] memory uris = new string[](3);
        uris[0] = "uri0";
        uris[1] = "uri1";
        uris[2] = "uri2";

        manager = new FriendKeyManager(subscriptionId, address(functionRouter), address(vrfCoordinator), uris);
    }

    function testRegister() public {
        string memory _uuid = "f482a971-6d3e-4124-abf9-7a27d2834d97";
        fixtureRegister(_uuid, msg.sender);
        assertEq(manager.isRegistered(_uuid), true);
        assertEq(manager.addressUUIDs(msg.sender), _uuid);
        assertEq(manager.uuidAddresses(_uuid), msg.sender);
    }

    function testMint() public {
        fixtureRegisterMin();
        uint256 id = fixtureMint(msg.sender, 1, 1);
        uint256 balance = IERC1155(manager.keys(0)).balanceOf(msg.sender, id);
        assertEq(balance, 1);
    }

    function testBatchMint() public {
        fixtureRegisterMin();

        uint256 amount = 5;
        (uint256[] memory ids, uint256[] memory values) = fixtureBatchMint(msg.sender, amount, 1);

        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            uint balance = IERC1155(manager.keys(0)).balanceOf(msg.sender, ids[i]);
            assertGt(balance, 0);
            sum += values[i];
        }

        assertEq(sum, amount);
    }

    function testMintDigest() public {
        
    }

    function fixtureRegister(string memory _uuid, address addr) public {
        string memory _token = "4ce8c2fd-0f32-42df-a7ce-6d19f5507a28";
        manager.register(_uuid, _token);
        bytes memory response = abi.encode(uint256(uint160(bytes20(addr)))); 
        bytes memory err = bytes(""); 
        uint96 juelsPerGas = 0;
        uint96 costWithoutFulfillment = 0;
        address transmitter = address(this);
        FunctionsResponse.Commitment memory commitment = FunctionsResponse.Commitment({
            requestId: manager.s_lastRequestId(),
            coordinator: address(0),
            estimatedTotalCostJuels: 0,
            client: address(manager),
            subscriptionId: 4070,
            callbackGasLimit: 0,
            adminFee: 0,
            donFee: 0,
            gasOverheadBeforeCallback: 0,
            gasOverheadAfterCallback: 0,
            timeoutTimestamp: 0
        });
        functionRouter.fulfill(response, err, juelsPerGas, costWithoutFulfillment, transmitter, commitment);
    }

    function fixtureRegisterMin() public {
        uint256 minAmount = manager.MIN_USERS();
        fixtureRegister("msg.sender", msg.sender);
        for (uint256 i = 0; i < minAmount; i++) {
            string memory _uuid = string(abi.encodePacked(i));
            vm.prank(address(bytes20(abi.encodePacked(i))));
            fixtureRegister(_uuid, msg.sender);
            vm.stopPrank();
        }
    }

    function fixtureMint(address to, uint256 amount, uint256 seed) public returns (uint) {
        uint256 fee = manager.minFee();
        manager.mint{value: fee}(to);
        uint256 requestId = vrfCoordinator.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        uint256 id = getWeightedRandomIndex(seed, 0);
        vrfCoordinator.fullfilRandomWord(address(manager), requestId, randomWords);
        return id;
    }

    function fixtureBatchMint(address to, uint256 amount, uint256 seed) public returns (uint256[] memory, uint256[] memory) {
        uint256 fee = manager.minFee();
        manager.batchMint{value: fee * amount}(msg.sender, amount);
        uint256 requestId = vrfCoordinator.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory values = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = getWeightedRandomIndex(seed, i);
            values[i] = 1;
        }

        vrfCoordinator.fullfilRandomWord(address(manager), requestId, randomWords);
        return (ids, values);
    }

    function getWeightedRandomIndex(uint256 _seed, uint256 _index) public view returns (uint) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_seed, _index, block.timestamp, block.prevrandao, address(vrfCoordinator))));
        uint len = manager.numUsers();
        uint startIndex = randomNumber % len;

        uint end = (startIndex + manager.RANDOM_WINDOW());
        uint endIndex = end < len ? end : len;

        uint totalWeight = 0;
        for (uint i = startIndex; i < endIndex; i++) {
            totalWeight += manager.prices(i);
        }

        randomNumber = uint256(keccak256(abi.encodePacked(randomNumber + 1))) % totalWeight;
        uint256 cumulativeWeight = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            cumulativeWeight += manager.prices(i);
            if (randomNumber < cumulativeWeight) {
                return i;
            }
        }

        // Should never reach here, but return 0 in case of unforeseen circumstances
        return 0;
    }

}