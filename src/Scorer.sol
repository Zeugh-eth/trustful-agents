// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IScorer} from "./interfaces/IScorer.sol";
import {IAttestationRegistry} from "./interfaces/IAttestationRegistry.sol";

/**
 * @title Scorer
 * @notice Base abstract contract for deterministic scoring with immutable weights
 */
abstract contract Scorer is IScorer {
    uint8 public immutable wCode;
    uint8 public immutable wClarity;
    uint8 public immutable wTime;

    constructor(uint8 _wCode, uint8 _wClarity, uint8 _wTime) {
        require(_wCode + _wClarity + _wTime == 100, "Weights must sum to 100");
        wCode = _wCode;
        wClarity = _wClarity;
        wTime = _wTime;
    }

    function calculateScore(
        IAttestationRegistry.Attestation[] calldata attestations
    ) external view override returns (uint256 score) {
        if (attestations.length == 0) return 0;
        
        uint256 totalScore = 0;
        
        for (uint256 i = 0; i < attestations.length; i++) {
            IAttestationRegistry.Attestation memory att = attestations[i];
            uint256 attScore = (
                uint256(att.codeQuality) * wCode +
                uint256(att.clarity) * wClarity +
                uint256(att.timeliness) * wTime
            ) / 100;
            totalScore += attScore;
        }
        
        return totalScore / attestations.length;
    }

    function calculateRanking(
        uint256[] calldata agentIds,
        IAttestationRegistry.Attestation[][] calldata attestationsByAgent
    ) external view override returns (uint256[] memory rankedAgentIds, uint256[] memory scores) {
        require(agentIds.length == attestationsByAgent.length, "Length mismatch");
        
        scores = new uint256[](agentIds.length);
        
        for (uint256 i = 0; i < agentIds.length; i++) {
            if (attestationsByAgent[i].length == 0) {
                scores[i] = 0;
                continue;
            }
            
            uint256 totalScore = 0;
            for (uint256 j = 0; j < attestationsByAgent[i].length; j++) {
                IAttestationRegistry.Attestation memory att = attestationsByAgent[i][j];
                uint256 attScore = (
                    uint256(att.codeQuality) * wCode +
                    uint256(att.clarity) * wClarity +
                    uint256(att.timeliness) * wTime
                ) / 100;
                totalScore += attScore;
            }
            scores[i] = totalScore / attestationsByAgent[i].length;
        }
        
        rankedAgentIds = _sortByScore(agentIds, scores);
        return (rankedAgentIds, scores);
    }

    function _sortByScore(uint256[] memory ids, uint256[] memory scores)
        internal
        pure
        returns (uint256[] memory sorted)
    {
        sorted = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            sorted[i] = ids[i];
        }
        
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = i + 1; j < sorted.length; j++) {
                if (scores[j] > scores[i]) {
                    (scores[i], scores[j]) = (scores[j], scores[i]);
                    (sorted[i], sorted[j]) = (sorted[j], sorted[i]);
                }
            }
        }
        
        return sorted;
    }
}
