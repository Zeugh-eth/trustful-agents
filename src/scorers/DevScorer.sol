// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Scorer} from "../Scorer.sol";

/**
 * @title DevScorer
 * @notice Scorer optimized for developer DAOs (prioritizes code quality)
 * @dev Weights: 70% code, 20% clarity, 10% timeliness
 */
contract DevScorer is Scorer {
    constructor() Scorer(70, 20, 10) {}
}
