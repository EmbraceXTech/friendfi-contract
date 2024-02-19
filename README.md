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