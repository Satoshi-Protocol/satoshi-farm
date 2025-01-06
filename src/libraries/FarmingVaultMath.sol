// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library FarmingVaultMath {
    uint256 internal constant PENALTY_RATIO_PRECISION = 1e6;

    function computePenaltyAmount(uint256 _penaltyRatio, uint256 _amount) internal pure returns (uint256) {
        uint256 penaltyAmount = (_amount * _penaltyRatio) / PENALTY_RATIO_PRECISION;
        return penaltyAmount;
    }
}
