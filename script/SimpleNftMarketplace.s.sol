// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
// import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SimpleNftMarketplace} from "../src/SimpleNftMarketplace.sol";
import "forge-std/Script.sol";

contract DeploySimpleNftMarketplace is Script {
    function run() external {

        vm.startBroadcast();

        // Deploy the implementation contract
        SimpleNftMarketplace implementation = new SimpleNftMarketplace();

        // Encode the initializer data
        bytes memory data = abi.encodeWithSelector(
            SimpleNftMarketplace.initialize.selector,
            msg.sender // Admin address
        );

        // Deploy the proxy contract and initialize it
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            data
        );

        // Log the addresses
        console.log("Implementation contract deployed at:", address(implementation));
        console.log("Proxy contract deployed at:", address(proxy));

        vm.stopBroadcast();


        // vm.startBroadcast();

        // address admin = msg.sender; // Use the deployer as the admin
        // // SimpleNftMarketplace marketplace = new SimpleNftMarketplace();
        // // marketplace.initialize(admin);
        // address proxy = Upgrades.deployUUPSProxy(
        //     "SimpleNftMarketplace.sol",
        //     abi.encodeCall(SimpleNftMarketplace.initialize.selector, (admin))
        // );
        // vm.stopBroadcast();

        // console.log("SimpleNftMarketplace deployed at:", proxy);
        // SimpleNftMarketplace instance = SimpleNftMarketplace(proxy);

        // console.log("Admin:", instance.offerCount());
    }
}
