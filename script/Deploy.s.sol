// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/PredictionMarket.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Address MockIDRX Kamu (Pastikan ini benar dari wallet)
        address idrx = 0x4cBfeEf5e07CCb3EcF123BF3c847A683964dB970;

        // Deploy TANPA fixedStake
        new PredictionMarket(idrx);

        vm.stopBroadcast();
    }
}