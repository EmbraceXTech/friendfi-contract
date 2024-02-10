// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/FriendKeyManager.sol";

contract FriendKeyManagerTest is Test {

    FriendKeyManager public manager;


    function setUp() public {

        string[] memory uris = new string[](3);
        uris[0] = "uri0";
        uris[1] = "uri1";
        uris[2] = "uri2";

        manager = new FriendKeyManager(uris);
    }

    function test_Register() public {
        string memory _account = "sainy_tk";
        bytes memory _proof = bytes("");

        manager.register(_account, _proof);
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


}