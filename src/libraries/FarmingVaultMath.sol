// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library FarmingVaultMath {
    uint256 internal constant REFUND_RATIO_PRECISION = 1e6;

    function computeRefundAmount(uint256 _refundRatio, uint256 _amount) internal pure returns (uint256) {
        uint256 refundAmount = (_amount * _refundRatio) / REFUND_RATIO_PRECISION;
        return refundAmount;
    }
}
