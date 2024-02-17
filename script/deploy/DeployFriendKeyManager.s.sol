// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/FriendKeyManager.sol";

contract DeployFriendKeyManager is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint64 functionSubscriptionId = 4070;
        uint64 vrfSubscriptionId = 1408;
        address functionRouter = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
        address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

        string[] memory uris = new string[](3);
        uris[0] = "uri0";
        uris[1] = "uri1";
        uris[2] = "uri2";

        new FriendKeyManager(functionSubscriptionId, address(functionRouter), vrfSubscriptionId, address(vrfCoordinator), uris);
        vm.stopBroadcast();
    }
}
