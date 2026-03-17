// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Scorer} from "../Scorer.sol";

/**
 * @title CommunityScorer
 * @notice Scorer optimized for community DAOs (prioritizes communication)
 * @dev Weights: 20% code, 70% clarity, 10% timeliness
 */
contract CommunityScorer is Scorer {
    constructor() Scorer(20, 70, 10) {}
}
