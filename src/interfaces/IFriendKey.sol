// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IFriendKey is IERC1155  {

    function mint(address _to, uint _tokenId, uint _value) external;
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) external;
    function burn(address _from, uint _tokenId, uint _value) external;
    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _values) external;

}
