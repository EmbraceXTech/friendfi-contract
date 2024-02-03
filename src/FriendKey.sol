// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FriendKey is ERC1155, Ownable  {

    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    function mint(address _to, uint _tokenId, uint _value) public onlyOwner {
        _mint(_to, _tokenId, _value, bytes(""));
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) public onlyOwner {
        _mintBatch(_to, _ids, _values, bytes(""));
    }

    function burn(address _from, uint _tokenId, uint _value) public onlyOwner {
        _burn(_from, _tokenId, _value, bytes(""));
    }

    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) public onlyOwner {
        _burnBatch(_from, _ids, _values, bytes(""));
    }

}
