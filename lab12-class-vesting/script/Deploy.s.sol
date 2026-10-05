// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Script, console} from "forge-std/Script.sol";
import {ClassVesting} from "../src/ClassVesting.sol";

/// Uso:
///   BENEFICIARIES=0xA,0xB,0xC,0xD,0xE,0xF,0xG forge script script/Deploy.s.sol --rpc-url $RPC --account <cuenta> --broadcast
contract Deploy is Script {
    uint64 constant CLIFF = 1790186400; // mié 23 Sep 2026 12:00 GT (UTC-6)
    uint64 constant END = 1790272800; //   jue 24 Sep 2026 12:00 GT

    function run() external returns (ClassVesting vesting) {
        address[] memory beneficiaries = vm.envAddress("BENEFICIARIES", ",");
        vm.startBroadcast();
        vesting = new ClassVesting(beneficiaries, CLIFF, END);
        vm.stopBroadcast();
        console.log("ClassVesting:", address(vesting));
        console.log("ClassToken:  ", address(vesting.token()));
    }
}
