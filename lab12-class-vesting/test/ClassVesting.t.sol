// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {ClassVesting} from "../src/ClassVesting.sol";
import {ClassToken} from "../src/ClassToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClassVestingTest is Test {
    uint64 constant CLIFF = 1790186400;
    uint64 constant END = 1790272800;

    ClassVesting vesting;
    IERC20 token;
    address[] students;

    function setUp() public {
        for (uint256 i = 0; i < 7; i++) {
            students.push(makeAddr(string.concat("student", vm.toString(i))));
        }
        vm.warp(CLIFF - 7 days); // deploy una semana antes del cliff
        vesting = new ClassVesting(students, CLIFF, END);
        token = vesting.token();
    }

    // ---------- deploy / supply ----------
    function test_SupplyIs7000AndHeldByVesting() public view {
        assertEq(token.totalSupply(), 7_000 ether);
        assertEq(token.balanceOf(address(vesting)), 7_000 ether);
    }

    function test_EachStudentHas1000() public view {
        for (uint256 i = 0; i < 7; i++) {
            assertEq(vesting.allocation(students[i]), 1_000 ether);
        }
        assertEq(vesting.beneficiaries().length, 7);
    }

    function test_TimestampsAreAbsoluteGT() public view {
        assertEq(vesting.cliff(), 1790186400); // 2026-09-23 18:00 UTC = 12:00 GT
        assertEq(vesting.end(), 1790272800); //   2026-09-24 18:00 UTC = 12:00 GT
        assertEq(vesting.end() - vesting.cliff(), 1 days);
    }

    function test_RevertWhen_WrongCount() public {
        address[] memory six = new address[](6);
        vm.expectRevert(abi.encodeWithSelector(ClassVesting.WrongBeneficiaryCount.selector, 6));
        new ClassVesting(six, CLIFF, END);
    }

    function test_RevertWhen_Duplicate() public {
        address[] memory dup = students;
        dup[6] = students[0];
        vm.expectRevert(abi.encodeWithSelector(ClassVesting.InvalidBeneficiary.selector, students[0]));
        new ClassVesting(dup, CLIFF, END);
    }

    // ---------- schedule ----------
    function test_NothingBeforeCliff() public {
        vm.warp(CLIFF - 1);
        assertEq(vesting.releasable(students[0]), 0);
        vm.prank(students[0]);
        vm.expectRevert(ClassVesting.NothingToClaim.selector);
        vesting.claim();
    }

    function test_CliffUnlocks100() public {
        vm.warp(CLIFF);
        assertEq(vesting.releasable(students[0]), 100 ether);
    }

    function test_HalfwayIs550() public {
        vm.warp(CLIFF + 12 hours);
        assertEq(vesting.releasable(students[0]), 550 ether);
    }

    function test_FullyVestedAtEnd() public {
        vm.warp(END);
        assertEq(vesting.releasable(students[0]), 1_000 ether);
        vm.warp(END + 365 days);
        assertEq(vesting.releasable(students[0]), 1_000 ether);
    }

    // ---------- claims ----------
    function test_ClaimPostCliffThenFullClaim() public {
        address s = students[3];
        vm.warp(CLIFF + 6 hours); // 100 + 900/4 = 325
        vm.prank(s);
        assertEq(vesting.claim(), 325 ether);
        assertEq(token.balanceOf(s), 325 ether);

        vm.warp(END + 1);
        vm.prank(s);
        assertEq(vesting.claim(), 675 ether);
        assertEq(vesting.claimed(s), 1_000 ether);
        assertEq(token.balanceOf(s), 1_000 ether);

        vm.prank(s);
        vm.expectRevert(ClassVesting.NothingToClaim.selector);
        vesting.claim();
    }

    function test_ClaimOnlyOwn() public {
        vm.warp(END);
        vm.prank(students[0]);
        vesting.claim();
        // el claim de student0 no toca lo de student1
        assertEq(token.balanceOf(students[1]), 0);
        assertEq(vesting.claimed(students[1]), 0);
        assertEq(vesting.releasable(students[1]), 1_000 ether);
    }

    function test_RevertWhen_OutsiderClaims() public {
        address outsider = makeAddr("outsider");
        vm.warp(END);
        vm.prank(outsider);
        vm.expectRevert(abi.encodeWithSelector(ClassVesting.NotBeneficiary.selector, outsider));
        vesting.claim();
    }

    function test_AllSevenClaimEmptiesVesting() public {
        vm.warp(END);
        for (uint256 i = 0; i < 7; i++) {
            vm.prank(students[i]);
            vesting.claim();
            assertEq(token.balanceOf(students[i]), 1_000 ether);
        }
        assertEq(token.balanceOf(address(vesting)), 0);
    }

    // ---------- fuzz ----------
    function testFuzz_VestedMonotonicAndCapped(uint64 t1, uint64 t2) public view {
        t1 = uint64(bound(t1, CLIFF - 2 days, END + 2 days));
        t2 = uint64(bound(t2, t1, END + 2 days));
        uint256 v1 = vesting.vestedAmount(students[0], t1);
        uint256 v2 = vesting.vestedAmount(students[0], t2);
        assertLe(v1, v2);
        assertLe(v2, 1_000 ether);
    }

    function testFuzz_ManyClaimsSumTo1000(uint64[5] memory offsets) public {
        address s = students[2];
        uint64 t = CLIFF;
        for (uint256 i = 0; i < offsets.length; i++) {
            t = uint64(bound(offsets[i], t, END));
            vm.warp(t);
            if (vesting.releasable(s) > 0) {
                vm.prank(s);
                vesting.claim();
            }
        }
        vm.warp(END);
        if (vesting.releasable(s) > 0) {
            vm.prank(s);
            vesting.claim();
        }
        assertEq(vesting.claimed(s), 1_000 ether);
        assertEq(token.balanceOf(s), 1_000 ether);
    }
}
