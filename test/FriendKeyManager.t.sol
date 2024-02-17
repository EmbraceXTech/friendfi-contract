// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FriendKeyManager.sol";
import "./contracts/TestFunctionsRouter.sol";
import "./contracts/TestVRFCoordinator.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {FunctionsResponse} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol";

contract FriendKeyManagerTest is Test, IERC1155Receiver {

    FriendKeyManager public manager;
    TestFunctionsRouter public functionRouter;
    TestVRFCoordinator public vrfCoordinator;

    // Test variable
    mapping(uint256 => uint256) sums;

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
        fixtureRegister(_uuid, address(this));
        assertEq(manager.isRegistered(_uuid), true);
        assertEq(manager.addressUUIDs(address(this)), _uuid);
        assertEq(manager.uuidAddresses(_uuid), address(this));
    }

    function testMint() public {
        fixtureRegisterMin();
        uint256 id = fixtureMint(address(this), 1, 1);
        uint256 balance = IERC1155(manager.keys(0)).balanceOf(address(this), id);
        assertEq(balance, 1);
    }

    function testBatchMint() public {
        fixtureRegisterMin();

        uint256 amount = 5;
        (uint256[] memory ids, uint256[] memory values) = fixtureBatchMint(address(this), amount, 1);

        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            uint balance = IERC1155(manager.keys(0)).balanceOf(address(this), ids[i]);
            assertEq(values[i], balance);
            sum += values[i];
        }

        assertEq(sum, amount);
    }

    function testMintDigest() public {
        fixtureRegisterMin();

        uint256 amount = 10;
        uint256 seed = 1;
        uint256 level = 0;

        (uint256[] memory ids, uint256[] memory values) = fixtureBatchMint(address(this), amount, seed);
        (uint256[] memory ids2, uint256[] memory values2) = fixtureMintDigest(address(this), level, ids, values, seed);

        uint256 sum = 0;
        for (uint256 i = 0; i < values2.length; i++) {
            uint balance = IERC1155(manager.keys(0)).balanceOf(address(this), ids2[i]);
            sum += values2[i];
            assertEq(values2[i], balance);
        }
        uint mintAmount = manager.DIGEST_RETURNS(level) * amount / manager.DIGEST_BATCH();
        assertEq(sum, mintAmount);
    }

    function testMerge() public {
        fixtureRegisterMin();

        uint256 amount = 50;
        uint256 seed = 1;
        uint256 level = 0;

        uint fee = manager.MERGE_FEES(level);
        uint mergePieces = manager.MERGE_PIECES();

        (uint256[] memory ids, uint256[] memory values) = fixtureBatchMint(address(this), amount, seed);
        
        uint mergeId;
        for (uint i = 0; i < ids.length; i++) {
            if (values[i] > mergePieces) {
                mergeId = ids[i];
                break;
            }
        }

        uint balBefore = IERC1155(manager.keys(level)).balanceOf(address(this), mergeId);
        manager.merge{value: fee}(mergeId, level);

        uint balAfter = IERC1155(manager.keys(level)).balanceOf(address(this), mergeId);
        uint nextLevelBal = IERC1155(manager.keys(level+1)).balanceOf(address(this), mergeId);


        assertEq(balAfter, balBefore - mergePieces);
        assertEq(nextLevelBal, 1);
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
        fixtureRegister("address(this)", address(this));
        for (uint256 i = 0; i < minAmount; i++) {
            string memory _uuid = string(abi.encodePacked(i));
            vm.prank(address(bytes20(abi.encodePacked(i))));
            fixtureRegister(_uuid, address(this));
            vm.stopPrank();
        }
    }

    function fixtureMint(address sender, uint256 amount, uint256 seed) public returns (uint) {
        uint256 fee = manager.minFee();
        manager.mint{value: fee}(sender);
        uint256 requestId = vrfCoordinator.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        uint256 id = getWeightedRandomIndex(seed, 0);
        vrfCoordinator.fullfilRandomWord(address(manager), requestId, randomWords);
        return id;
    }

    function fixtureBatchMint(address sender, uint256 amount, uint256 seed) public returns (uint256[] memory, uint256[] memory) {
        uint256 fee = manager.minFee();
        manager.batchMint{value: fee * amount}(sender, amount);
        uint256 requestId = vrfCoordinator.lastRequestId();
        return fixtureFulfillBatchMint(amount, seed, requestId);
    }

    function fixtureMintDigest(address sender, uint256 _level, uint256[] memory _ids, uint256[] memory _values, uint seed) public returns (uint256[] memory, uint256[] memory) {
        manager.mintDigest(_level, _ids, _values, address(this));
        uint256 requestId = vrfCoordinator.lastRequestId();
        uint burnAmount;
        for (uint256 i = 0; i < _values.length; i++) {
            burnAmount += _values[i];
        }
        uint amount = manager.DIGEST_RETURNS(_level) * burnAmount / manager.DIGEST_BATCH();
        return fixtureFulfillBatchMint(amount, seed, requestId);
    }

    function fixtureFulfillBatchMint(uint256 amount, uint256 seed, uint256 requestId) public returns (uint256[] memory, uint256[] memory) {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;

        uint maxId;
        for (uint256 i = 0; i < amount; i++) {
            uint index = getWeightedRandomIndex(seed, i);
            sums[index] += 1;
            if (index > maxId) maxId = index;
        }

        uint len;
        for (uint256 i = 0; i <= maxId; i++) {
            if(sums[i] > 0) {
                len++;
            }
        }

        uint256[] memory ids = new uint256[](len);
        uint256[] memory values = new uint256[](len);
        uint256 j = 0;
        for (uint256 i = 0; i <= maxId; i++) {
            if(sums[i] > 0) {
                ids[j] = i;
                values[j] = sums[i];
                j++;
            }
        }

        for (uint256 i = 0; i <= maxId; i++) {
            sums[i] = 0;
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

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return (
            interfaceId == type(IERC1155).interfaceId
        );
    }

    receive() payable external {}

}