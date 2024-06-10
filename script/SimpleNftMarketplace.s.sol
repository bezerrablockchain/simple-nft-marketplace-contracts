// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SimpleNftMarketplace} from "../src/SimpleNftMarketplace.sol";
import "forge-std/Script.sol";

contract DeploySimpleNftMarketplace is Script {
    function run() external {
        vm.startBroadcast();

        address admin = msg.sender; // Use the deployer as the admin
        SimpleNftMarketplace marketplace = new SimpleNftMarketplace();
        marketplace.initialize(admin);

        vm.stopBroadcast();
    }
}
