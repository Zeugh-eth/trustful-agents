// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAttestationRegistry} from "./IAttestationRegistry.sol";

/**
 * @title IScorer
 * @notice Deterministic scoring logic with immutable weights
 * @dev Each scorer applies different weight profiles to same attestations
 */
interface IScorer {
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Code quality weight (0-100)
     * @dev Immutable, set at construction
     */
    function wCode() external view returns (uint8);

    /**
     * @notice Communication clarity weight (0-100)
     * @dev Immutable, set at construction
     */
    function wClarity() external view returns (uint8);

    /**
     * @notice Delivery timeliness weight (0-100)
     * @dev Immutable, set at construction
     */
    function wTime() external view returns (uint8);

    /*//////////////////////////////////////////////////////////////
                        SCORING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate weighted score for an agent based on attestations
     * @dev score = (codeQuality * wCode + clarity * wClarity + timeliness * wTime) / 100
     * @param attestations Array of attestations for the agent
     * @return score Weighted score (0-10 scale, average across attestations)
     */
    function calculateScore(
        IAttestationRegistry.Attestation[] calldata attestations
    ) external view returns (uint256 score);

    /**
     * @notice Calculate ranking for multiple agents
     * @dev Returns agentIds sorted by score (highest first)
     * @param agentIds Array of agent IDs to rank
     * @param attestationsByAgent Array of attestation arrays (parallel to agentIds)
     * @return rankedAgentIds Sorted agent IDs (highest score first)
     * @return scores Corresponding scores for each ranked agent
     */
    function calculateRanking(
        uint256[] calldata agentIds,
        IAttestationRegistry.Attestation[][] calldata attestationsByAgent
    ) external view returns (uint256[] memory rankedAgentIds, uint256[] memory scores);
}
