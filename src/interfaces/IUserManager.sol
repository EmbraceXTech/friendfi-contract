// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUserManager {
    function register(string memory _uuid, string memory _token) external;
    function isRegistered(string memory _uuid) external view returns(bool);
    function addressId(address _addr) external view returns(uint);
    function addressUUIDs(address _addr) external view returns(string memory);
    function uuidAddresses(string memory _uuid) external view returns(address);
    function addresses(uint256 _index) external view returns(address);
    function uuids(uint256 _index) external view returns(string memory);
    function numUsers() external view returns (uint256);
}
