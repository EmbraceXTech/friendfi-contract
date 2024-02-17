// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./UserManagerFunctions.sol";
import "./interfaces/IUserManager.sol";

contract UserManager is IUserManager, UserManagerFunctions {
    constructor(
        uint64 functionSubscriptionId_,
        address router_
    ) UserManagerFunctions(functionSubscriptionId_, router_) {}
    
    function register(string memory _uuid, string memory _token) public override {
        require(!isRegistered(_uuid), "Already registered");
        _validateParticleAuth(_uuid, _token);
    }

    function isRegistered(string memory _uuid) public override view returns(bool) {
        return _registered[_uuid];
    }

    function addressId(address _addr) public override view returns(uint) {
        return _addressIds[_addr];
    }

    function addressUUIDs(address _addr) public override view returns(string memory) {
        uint id = _addressIds[_addr];
        return uuids(id);
    }

    function uuidAddresses(string memory _uuid) public override view returns(address) {
        uint id = _uuidIds[_uuid];
        return addresses(id);
    }

    function addresses(uint256 _index) public override view returns(address) {
        return _addresses[_index];
    }

    function uuids(uint256 _index) public override view returns(string memory) {
        return _uuids[_index];
    }

    function numUsers() public override view returns (uint256) {
        return _addresses.length;
    }

}
