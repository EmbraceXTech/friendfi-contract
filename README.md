## FriendFi Contract
**FriendFi is a social media with DeFi power. It enables people to reach out each other using financial mechanism relying on smart contract.**

<img src="./public/logo-friendfi.png" width="200" />

There are 3 main contracts FriendFi:
-   **FriendKeyManager**: The main entrypoing contract for unlocking friend connection.
-   **UserManager**: The storage contract that holds list of users in the system.
-   **FriendKey**: An ERC1155 token contract used to represent friend connections.

The contracts integrated with Chainlink and Particle Auth.
-   **UserManagerFunctions**: User manager relies on Chainlink Functions to validate user authentication from Particle Auth service.
-   **FriendKeyManagerVRF**: Friend key manager relies on Chainlink VRF to feed random numbers for friend key mining process.

## Deployments

### Avalanche Fuji
- "UserManager": "0x36BdBF70B474D6A2aF3F17531Cfe1a9Ea1036c03"
- "FriendKeyManager": "0xb64aFd1277EF94F214e4BF8F51B7018Fa0F7C9c9"
- "FriendKey0": "0xC4Dd875618429b8E015f5B612Ed4d18af54d34E7"
- "FriendKey1": "0xd8B16F1007A04a12b84440B96a055f1788BB3d43"
- "FriendKey2": "0x5ff752925cC6223661d18F384940D4223FE5F92b"

## Usage

### Installation
1. Install libs
```shell
$ forge install
```
2. Install npm
```shell
$ npm i
```

### Build

```shell
$ npm run build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ ./commands/deploy-friend-key-manager.sh
```

### Links
- [Frontend Example](https://github.com/EmbraceXTech/friendfi-frontend)