// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {LabToken} from "../src/LabToken.sol";

/// Handler: acota las acciones del fuzzer a transfers/approve/transferFrom entre actores conocidos.
contract Handler is Test {
    LabToken public token;
    address[] public actors;

    constructor(LabToken token_, address[] memory actors_) {
        token = token_;
        actors = actors_;
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(from));
        vm.prank(from);
        token.transfer(to, amount);
    }

    function approveAndPull(uint256 ownerSeed, uint256 spenderSeed, uint256 amount) external {
        address owner_ = actors[ownerSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(owner_));
        vm.prank(owner_);
        token.approve(spender, amount);
        vm.prank(spender);
        token.transferFrom(owner_, spender, amount);
    }

    function actorsLength() external view returns (uint256) {
        return actors.length;
    }
}

contract LabTokenInvariantTest is Test {
    LabToken token;
    Handler handler;
    address treasury = makeAddr("treasury");
    uint256 constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new LabToken(SUPPLY, treasury, 250); // 2.5%
        address[] memory actors = new address[](4);
        actors[0] = makeAddr("a");
        actors[1] = makeAddr("b");
        actors[2] = makeAddr("c");
        actors[3] = treasury;
        for (uint256 i = 0; i < 3; i++) token.transfer(actors[i], 100_000 ether);
        handler = new Handler(token, actors);
        targetContract(address(handler));
    }

    /// totalSupply nunca cambia (no hay mint/burn post-deploy)
    function invariant_SupplyConstant() public view {
        assertEq(token.totalSupply(), SUPPLY);
    }

    /// suma de balances de todos los holders == totalSupply (la fee no crea ni destruye tokens)
    function invariant_BalancesSumToSupply() public view {
        uint256 sum = token.balanceOf(address(this));
        for (uint256 i = 0; i < handler.actorsLength(); i++) {
            sum += token.balanceOf(handler.actors(i));
        }
        assertEq(sum, token.totalSupply());
    }
}
