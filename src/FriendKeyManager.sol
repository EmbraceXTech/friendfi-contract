// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./FriendKey.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FriendKeyManager is Ownable {

    FriendKey[3] public keys;

    address[] public users;
    string[] public accounts;
    uint[] public prices;

    mapping(address => bool) public userRegistered;
    mapping(string => bool) public accountRegistered;

    mapping(address => bytes) private _registerRequest;

    uint256 immutable public RANDOM_WINDOW = 1000;
    uint256 immutable public MIN_USERS = 10;
    uint256 immutable public MERGE_PIECES = 3;
    uint256 immutable public USER_DIVIDEN = 5000; // 0.5 (decimals = 4)
    uint256 immutable public DIGEST_BATCH = 10;

    uint256[2] public MERGE_FEES;
    uint256[3] public DIGEST_RETURNS;

    uint256 public latestMintFee;
    uint256 public lastMintTimestamp;
    uint256 public cooldownDuration = 1 days;
    uint256 public feeChangeRate = 2;
    uint256 public minFee = 0.0005 ether;
    uint256 public maxFee = 1 ether;

    constructor(string[] memory uris) Ownable(msg.sender) {
        require(uris.length == 3, "Size mismatch");

        // keys = new FriendKey[](3);
        for (uint i = 0; i < 3; i++) {
            keys[i] = new FriendKey(uris[i]);
        }

        // MERGE_FEES = new uint256[](2);
        MERGE_FEES[0] = 0.001 ether;
        MERGE_FEES[1] = 0.005 ether;

        // DIGEST_RETURNS = new uint256[](3);
        DIGEST_RETURNS[0] = 1;
        DIGEST_RETURNS[1] = 4;
        DIGEST_RETURNS[2] = 10;
    }
    
    function register(string memory _account, bytes calldata _proof) public {
        require(!userRegistered[msg.sender] && !accountRegistered[_account], "Already registered");
        // TODO: call chainlink function to check the proof of Social media
        _registerRequest[msg.sender] = bytes("");
    }

    function _fulfillRegister() public {
        users.push(address(0));
        accounts.push("");

        userRegistered[address(0)] = true;
        accountRegistered[""] = true;
    }

    function mint() public payable {
        require(users.length > MIN_USERS, "User amount is too low");

        uint fee = getMintFee(1);
        require(msg.value >= fee, "Insufficient fee");

        _mint(msg.sender, 1);

        // payment return 
        uint cashReturn = msg.value - fee;
        if (cashReturn > 0) {
            payable(msg.sender).transfer(cashReturn);
        }
    }

    function batchMint(uint _mintAmount) public payable {
        require(users.length > MIN_USERS, "User amount is too low");

        uint fee = getMintFee(_mintAmount);
        require(msg.value >= fee, "Insufficient fee");

       _mint(msg.sender, _mintAmount);

        // payment return 
        uint cashReturn = msg.value - fee;
        if (cashReturn > 0) {
            payable(msg.sender).transfer(cashReturn);
        }
    }

    function mintDigest(uint _level, uint[] memory _ids) public {
        require(_ids.length % DIGEST_BATCH == 0, "Batch size mismatch");
        for (uint i = 0; i < _ids.length; i++) {
            keys[_level].burn(msg.sender, _ids[i], MERGE_PIECES);
        }

        uint _mintAmount = DIGEST_RETURNS[_level] * _ids.length / DIGEST_BATCH;
        _mint(msg.sender, _mintAmount);
    }

    function merge(uint _id, uint _level) public payable {
        require(_level < 2, "Exceed maximum level");
        uint fee = MERGE_FEES[_level];

        require(msg.value == fee, "Fee mismatch");

        keys[_level].burn(msg.sender, _id, MERGE_PIECES);
        keys[_level + 1].mint(msg.sender, _id, 1);

        uint userFee = fee * USER_DIVIDEN / 10e4;
        payable(users[_id]).transfer(userFee);
    }

    function _getWeightedRandomIndex() internal view returns (uint) {
        // TODO: user VRF instead
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        uint startIndex = randomNumber % prices.length;

        uint end = (startIndex + RANDOM_WINDOW);
        uint endIndex = end < prices.length ? end : prices.length;

        uint totalWeight = 0;
        for (uint i = startIndex; i < endIndex; i++) {
            totalWeight += prices[i];
        }
        
        // TODO: user VRF instead
        randomNumber = uint256(keccak256(abi.encodePacked(randomNumber + 1))) % totalWeight;
        uint256 cumulativeWeight = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            cumulativeWeight += prices[i];
            if (randomNumber < cumulativeWeight) {
                return i;
            }
        }

        // Should never reach here, but return 0 in case of unforeseen circumstances
        return 0;
    }

    function getMintFee(uint number) public view returns (uint) {
        // TODO: fix dynamic fee algorithm
        uint256 elapsedTime = block.timestamp - lastMintTimestamp;
        uint256 feeChange = feeChangeRate * elapsedTime * elapsedTime / cooldownDuration * cooldownDuration;
        uint256 adjustedMintFee = latestMintFee + feeChange;

        adjustedMintFee = (adjustedMintFee < minFee) ? minFee : adjustedMintFee;
        adjustedMintFee = (adjustedMintFee > maxFee) ? maxFee : adjustedMintFee;

        return adjustedMintFee * number;
    }

    function _mint(address _to, uint _mintAmount) internal {
        uint[] memory tokenIds = new uint[](_mintAmount);
        uint[] memory values = new uint[](_mintAmount);
        for (uint i = 0; i < _mintAmount; i++) {
            tokenIds[i] = _getWeightedRandomIndex();
            values[i] = 1;
        }

        keys[0].mintBatch(_to, tokenIds, values);
    }

    function claimFee(uint _value) public {
        payable(owner()).transfer(_value);
    }


}
