// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155  {

    constructor(string memory uri_) ERC1155(uri_) {}

    function mint(address _to, uint _tokenId, uint _value) public {
        _mint(_to, _tokenId, _value, bytes(""));
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) public {
        _mintBatch(_to, _ids, _values, bytes(""));
    }

    function burn(address _from, uint _tokenId, uint _value) public {
        _burn(_from, _tokenId, _value);
    }

    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) public {
        _burnBatch(_from, _ids, _values);
    }

}
