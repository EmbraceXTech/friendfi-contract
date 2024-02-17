// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/FriendKeyManager.sol";

contract DeployFriendKeyManager is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address userManager = 0x36BdBF70B474D6A2aF3F17531Cfe1a9Ea1036c03;
        uint64 vrfSubscriptionId = 1408;
        address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

        string[] memory uris = new string[](3);
        uris[0] = "uri0";
        uris[1] = "uri1";
        uris[2] = "uri2";

        new FriendKeyManager(userManager, vrfSubscriptionId, address(vrfCoordinator), uris);
        vm.stopBroadcast();
    }
}
