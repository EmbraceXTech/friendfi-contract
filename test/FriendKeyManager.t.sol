// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FriendKeyManager.sol";
import "./contracts/TestFunctionsRouter.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {FunctionsResponse} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol";

contract FriendKeyManagerTest is Test, IERC1155Receiver {

    FriendKeyManager public manager;
    TestFunctionsRouter public functionRouter;

    function setUp() public {
        uint64 subscriptionId = 4070;
        functionRouter = new TestFunctionsRouter();

        string[] memory uris = new string[](3);
        uris[0] = "uri0";
        uris[1] = "uri1";
        uris[2] = "uri2";

        manager = new FriendKeyManager(subscriptionId, address(functionRouter), uris);
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

    function testRegister() public {
        string memory _uuid = "f482a971-6d3e-4124-abf9-7a27d2834d97";
        fixtureRegister(_uuid, msg.sender);
        assertEq(manager.isRegistered(_uuid), true);
        assertEq(manager.addressUUIDs(msg.sender), _uuid);
        assertEq(manager.uuidAddresses(_uuid), msg.sender);
    }

    function testMint() public {
        fixtureRegisterMin();
        uint256 fee = manager.minFee();
        uint256 id = manager.mint{value: fee}();
        uint256 balance = IERC1155(manager.keys(0)).balanceOf(msg.sender, id);
        assertEq(balance, 1);
    }

    //  function testSellInsurance() public {
    //     uint _amount = 100 * 10 ** testERC20.decimals();

    //     testERC20.approve(address(azurancePool), _amount);
    //     azurancePool.sellInsurance(_amount);

    //     assertEq(azurancePool.totalValueLocked(), _amount);
    //     assertEq(IERC20(azurancePool.sellerToken()).balanceOf(address(this)), _amount);
    // }

    //  function testFail_BuyInsuranceExceedMax() public {
    //     uint _amount = 100 * 10 ** testERC20.decimals();
    //     vm.startPrank(address(1));
    //     testERC20.approve(address(azurancePool), _amount * 2);
    //     azurancePool.sellInsurance(_amount * 2);

    //     vm.stopPrank();
    //     testERC20.approve(address(azurancePool), _amount);
    //     azurancePool.buyInsurance(_amount);

    //     testERC20.approve(address(azurancePool), _amount);
    //     azurancePool.buyInsurance(_amount + 1);
    // }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }


}