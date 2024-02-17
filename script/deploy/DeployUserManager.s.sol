// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/UserManager.sol";

contract DeployUserManager is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint64 functionSubscriptionId = 4070;
        address functionRouter = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

        new UserManager(functionSubscriptionId, address(functionRouter));
        vm.stopBroadcast();
    }
}
