// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {LabToken} from "../src/LabToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract LabTokenTest is Test {
    LabToken token;
    address owner = address(this);
    address treasury = makeAddr("treasury");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new LabToken(SUPPLY, treasury, 100); // 1%
        token.transfer(alice, 10_000 ether); // owner exento: sin fee
    }

    // ---------- unit ----------
    function test_Metadata() public view {
        assertEq(token.name(), "Lab Token");
        assertEq(token.symbol(), "LAB");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), SUPPLY);
    }

    function test_TransferChargesFee() public {
        vm.prank(alice);
        token.transfer(bob, 1_000 ether);
        assertEq(token.balanceOf(bob), 990 ether);
        assertEq(token.balanceOf(treasury), 10 ether);
        assertEq(token.balanceOf(alice), 9_000 ether);
    }

    function test_ExemptSkipsFee() public {
        token.setFeeExempt(alice, true);
        vm.prank(alice);
        token.transfer(bob, 1_000 ether);
        assertEq(token.balanceOf(bob), 1_000 ether);
        assertEq(token.balanceOf(treasury), 0);
    }

    function test_TransferFromUsesAllowance() public {
        vm.prank(alice);
        token.approve(bob, 500 ether);
        vm.prank(bob);
        token.transferFrom(alice, bob, 500 ether);
        assertEq(token.allowance(alice, bob), 0);
        assertEq(token.balanceOf(bob), 495 ether);
    }

    function test_RevertWhen_InsufficientBalance() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, 0, 1));
        token.transfer(alice, 1);
    }

    function test_RevertWhen_FeeTooHigh() public {
        vm.expectRevert(abi.encodeWithSelector(LabToken.FeeTooHigh.selector, uint16(501)));
        token.setFeeBps(501);
    }

    function test_RevertWhen_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.setFeeBps(0);
    }

    // ---------- fuzz ----------
    function testFuzz_TransferConservesValue(uint256 amount, uint16 feeBps) public {
        amount = bound(amount, 0, token.balanceOf(alice));
        feeBps = uint16(bound(feeBps, 0, token.MAX_FEE_BPS()));
        token.setFeeBps(feeBps);

        uint256 before = token.balanceOf(alice) + token.balanceOf(bob) + token.balanceOf(treasury);
        vm.prank(alice);
        token.transfer(bob, amount);
        uint256 afterSum = token.balanceOf(alice) + token.balanceOf(bob) + token.balanceOf(treasury);

        assertEq(before, afterSum);
        assertEq(token.balanceOf(treasury), amount * feeBps / 10_000);
    }
}
