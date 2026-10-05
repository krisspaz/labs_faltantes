// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ClassToken} from "./ClassToken.sol";

/// @title ClassVesting — vesting multi-beneficiary de la clase (Lab 12)
/// @notice Un solo deploy crea el token (7_000) y lo custodia. Cada uno de los 7 beneficiaries
///         tiene 1_000: 100 se liberan en el cliff y 900 linealmente durante 1 día.
///         Timestamps absolutos en hora de Guatemala (UTC-6):
///           cliff = mié 23 Sep 2026 12:00 GT = 1790186400
///           end   = jue 24 Sep 2026 12:00 GT = 1790272800
/// @dev `claim()` siempre paga a `msg.sender`: nadie puede reclamar lo de otro.
contract ClassVesting {
    using SafeERC20 for IERC20;

    uint256 public constant BENEFICIARY_COUNT = 7;
    uint256 public constant ALLOCATION = 1_000 ether;
    uint256 public constant CLIFF_AMOUNT = 100 ether;
    uint256 public constant LINEAR_AMOUNT = ALLOCATION - CLIFF_AMOUNT; // 900

    uint64 public immutable cliff;
    uint64 public immutable end;
    IERC20 public immutable token;

    mapping(address => uint256) public allocation;
    mapping(address => uint256) public claimed;
    address[] private _beneficiaries;

    error WrongBeneficiaryCount(uint256 count);
    error InvalidBeneficiary(address beneficiary);
    error InvalidSchedule(uint64 cliff, uint64 end);
    error NotBeneficiary(address account);
    error NothingToClaim();

    event Claimed(address indexed beneficiary, uint256 amount, uint256 totalClaimed);

    constructor(address[] memory beneficiaries_, uint64 cliff_, uint64 end_) {
        if (beneficiaries_.length != BENEFICIARY_COUNT) revert WrongBeneficiaryCount(beneficiaries_.length);
        if (end_ <= cliff_) revert InvalidSchedule(cliff_, end_);

        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            address b = beneficiaries_[i];
            if (b == address(0) || allocation[b] != 0) revert InvalidBeneficiary(b); // cero o duplicado
            allocation[b] = ALLOCATION;
            _beneficiaries.push(b);
        }

        cliff = cliff_;
        end = end_;
        token = IERC20(address(new ClassToken(address(this))));
    }

    /// @notice Total vesteado para `beneficiary` en el instante `timestamp`.
    function vestedAmount(address beneficiary, uint64 timestamp) public view returns (uint256) {
        if (allocation[beneficiary] == 0 || timestamp < cliff) return 0;
        if (timestamp >= end) return ALLOCATION;
        return CLIFF_AMOUNT + (LINEAR_AMOUNT * (timestamp - cliff)) / (end - cliff);
    }

    /// @notice Lo que `beneficiary` puede reclamar ahora mismo.
    function releasable(address beneficiary) public view returns (uint256) {
        return vestedAmount(beneficiary, uint64(block.timestamp)) - claimed[beneficiary];
    }

    /// @notice Reclama todo lo liberado hasta ahora para `msg.sender`.
    function claim() external returns (uint256 amount) {
        if (allocation[msg.sender] == 0) revert NotBeneficiary(msg.sender);
        amount = releasable(msg.sender);
        if (amount == 0) revert NothingToClaim();
        claimed[msg.sender] += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount, claimed[msg.sender]);
    }

    function beneficiaries() external view returns (address[] memory) {
        return _beneficiaries;
    }
}
