// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract FriendKeyManagerFunctions is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // router - Hardcoded for Fuji
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    // address router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

    // donID - Hardcoded for Fuji
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;
    uint32 gasLimit = 300000;

    uint64 subscriptionId;
    mapping(bytes32 => string) public pendingUUID;

    // User database
    mapping(address => uint) internal _addressIds;
    mapping(string => uint) internal _uuidIds;
    mapping(string => bool) internal _registered;
    string[] internal _uuids;
    address[] internal _addresses;
    uint[] internal _prices;

    // Storage
    uint256 public minFee = 0.0005 ether;
    uint256 public maxFee = 1 ether;

    string source =
        "const UUID = args[0];"
        "const token = args[1];"
        "const authToken = `NDQ2OTdmZDItYjc4Zi00ZjEwLWE3YTktNzc4M2U3NzBkZDlhOnNQeThWUU1ZeU5rUDdYejdhSUh0RnJwRnZkcm40WldrR1Z0eDN0enU=`;"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://api.particle.network/server/rpc/#getUserInfo`,"
        "method: `POST`,"
        "headers: {"
        "    'accept': `application/json`,"
        "    'content-type': `application/json`,"
        "    'Authorization': `Basic ${authToken}`"
        "},"
        "data: {"
        "    jsonrpc: `2.0`, id: 1, method: `getUserInfo`,"
        "    params: [UUID, token]"
        "}"
        "});"
        "if (apiResponse.error) {"
        "console.error(apiResponse);"
        "throw Error(`Request failed`);"
        "}"
        "const { data } = apiResponse;"
        "const evmIndex = data.result.wallets.findIndex(item => item.chain === 'evm_chain');"
        "return Functions.encodeUint256(BigInt(data.result.wallets[evmIndex].publicAddress));";

    error UnexpectedRequestID(bytes32 requestId);

    event Response(
        bytes32 indexed requestId,
        string uuid,
        bytes response,
        bytes err
    );

    constructor(uint64 subscriptionId_, address router_) FunctionsClient(router_) ConfirmedOwner(msg.sender) {
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
        uint256 addrUint256 = bytesToUint256(s_lastResponse);
        address addr = uint256ToAddress(addrUint256);

        uint userId = _addresses.length;
        _addressIds[addr] = userId;
        _uuidIds[uuid] = userId;

        _uuids.push(uuid);
        _addresses.push(addr);
        _prices.push(minFee);
        _registered[uuid] = true;

        // Emit an event to log the response
        emit Response(requestId, uuid, s_lastResponse, s_lastError);
    }

    function bytesToUint256(bytes memory _input) public pure returns (uint256) {
        return uint256(bytes32(_input));
    }

    function uint256ToAddress(uint256 _input) public pure returns (address) {
        return address(bytes20(uint160(_input)));
    }
    
}
