// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Script, console} from "forge-std/Script.sol";
import {LabToken} from "../src/LabToken.sol";

contract Deploy is Script {
    function run() external returns (LabToken token) {
        address treasury = vm.envOr("TREASURY", msg.sender);
        uint16 feeBps = uint16(vm.envOr("FEE_BPS", uint256(100))); // 1%
        vm.startBroadcast();
        token = new LabToken(1_000_000 ether, treasury, feeBps);
        vm.stopBroadcast();
        console.log("LabToken:", address(token));
    }
}
