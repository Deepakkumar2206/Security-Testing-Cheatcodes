// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Vault.sol";

contract DeployVault is Script {
    function run() external {
        vm.startBroadcast();
        // tx.origin is the EOA used by --private-key; set as owner
        new Vault(tx.origin);
        vm.stopBroadcast();
    }
}
