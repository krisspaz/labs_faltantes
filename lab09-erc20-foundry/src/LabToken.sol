// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title LabToken — ERC-20 con fee-on-transfer opcional (Lab 09)
/// @notice Supply fijo minteado al deployer. Cada transfer entre cuentas no exentas
///         cobra `feeBps` (máx. 5%) que va al `treasury`. Mint y burn no pagan fee.
contract LabToken is ERC20, Ownable {
    uint16 public constant MAX_FEE_BPS = 500; // 5%
    uint16 public constant BPS = 10_000;

    uint16 public feeBps;
    address public treasury;
    mapping(address => bool) public feeExempt;

    error FeeTooHigh(uint16 feeBps);
    error ZeroAddress();

    event FeeUpdated(uint16 feeBps);
    event TreasuryUpdated(address treasury);
    event FeeExemptUpdated(address account, bool exempt);

    constructor(uint256 initialSupply, address treasury_, uint16 feeBps_)
        ERC20("Lab Token", "LAB")
        Ownable(msg.sender)
    {
        if (treasury_ == address(0)) revert ZeroAddress();
        if (feeBps_ > MAX_FEE_BPS) revert FeeTooHigh(feeBps_);
        treasury = treasury_;
        feeBps = feeBps_;
        feeExempt[msg.sender] = true;
        feeExempt[treasury_] = true;
        _mint(msg.sender, initialSupply);
    }

    function setFeeBps(uint16 feeBps_) external onlyOwner {
        if (feeBps_ > MAX_FEE_BPS) revert FeeTooHigh(feeBps_);
        feeBps = feeBps_;
        emit FeeUpdated(feeBps_);
    }

    function setTreasury(address treasury_) external onlyOwner {
        if (treasury_ == address(0)) revert ZeroAddress();
        treasury = treasury_;
        emit TreasuryUpdated(treasury_);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        feeExempt[account] = exempt;
        emit FeeExemptUpdated(account, exempt);
    }

    /// @dev OZ v5: único hook para transfer/mint/burn. La fee se cobra solo en transfers.
    function _update(address from, address to, uint256 value) internal override {
        if (from == address(0) || to == address(0) || feeBps == 0 || feeExempt[from] || feeExempt[to]) {
            super._update(from, to, value);
            return;
        }
        uint256 fee = (value * feeBps) / BPS;
        super._update(from, treasury, fee);
        super._update(from, to, value - fee);
    }
}
