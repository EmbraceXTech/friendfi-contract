// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract FriendKeyManagerFunctions is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

    // donID - Hardcoded for Fuji
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;
    uint32 gasLimit = 300000;

    uint64 subscriptionId;
    mapping(bytes32 => string) public pendingUUID;

    // User database
    mapping(address => string) internal _addressUUIDs;
    mapping(string => address) internal _uuidAddresses;
    string[] internal _uuids;
    address[] internal _addresses;

    string source =
        "const UUID = args[0];"
        "const token = args[1];"
        "const authToken = "
        "`NDQ2OTdmZDItYjc4Zi00ZjEwLWE3YTktNzc4M2U3NzBkZDlhOnNQeThWUU1ZeU5"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://api.particle.network/server/rpc/#getUserInfo`,"
        "method: `POST`,"
        "headers: {"
        "`accept`: `application/json`,"
        "`content-type`: `application/json`,"
        "`Authorization`: `Basic ${authToken}`"
        "  },"
        "    data: {jsonrpc: `2.0`, id: 1, method: `getUserInfo`,"
        "params: [UUID, token]}"
        "})"
        "if (apiResponse.error) {"
        "console.error(apiResponse)"
        "throw Error(`Request failed`)"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.result.wallets[0].publicAddress)";

    error UnexpectedRequestID(bytes32 requestId);

    event Response(
        bytes32 indexed requestId,
        string uuid,
        bytes response,
        bytes err
    );

    constructor(uint64 subscriptionId_) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        subscriptionId = subscriptionId_;
    }

    function _validateParticleAuth(string memory _uuid, string memory _token) internal {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); 

        string[] memory args = new string[](2);
        args[0] = _uuid;
        args[1] = _token;

        req.setArgs(args);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        pendingUUID[s_lastRequestId] = _uuid;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;

        string memory uuid = pendingUUID[requestId];
        address addr = bytesToAddress(response);

        _uuids.push(uuid);
        _addresses.push(addr);

        _uuidAddresses[uuid] = addr;
        _addressUUIDs[addr] = uuid;

        // Emit an event to log the response
        emit Response(requestId, target, s_lastResponse, s_lastError);
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }
    
}
