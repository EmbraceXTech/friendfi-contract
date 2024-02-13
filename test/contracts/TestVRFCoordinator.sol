// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract TestVRFCoordinator is VRFCoordinatorV2Interface {

    uint256 public lastRequestId;

  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory) {
    bytes32[] memory s_provingKeyHashes = new bytes32[](0);
    return (0, 0, s_provingKeyHashes);
  }

  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId) {
    return ++lastRequestId;
  }

  function createSubscription() external returns (uint64 subId) {
    return 0;
  }

  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) {
    address[] memory _consumers = new address[](0);
    return (0, 0, address(0), _consumers);
  }

  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external {}
  function acceptSubscriptionOwnerTransfer(uint64 subId) external {}
  function addConsumer(uint64 subId, address consumer) external {}
  function removeConsumer(uint64 subId, address consumer) external {}
  function cancelSubscription(uint64 subId, address to) external {}
  function pendingRequestExists(uint64 subId) external view returns (bool) {}

  function fullfilRandomWord(address target, uint256 requestId, uint256[] memory randomWords) external {
    VRFConsumerBaseV2(target).rawFulfillRandomWords(requestId, randomWords);
  }
}
