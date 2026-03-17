// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAttestationRegistry} from "./interfaces/IAttestationRegistry.sol";

/**
 * @title AttestationRegistry
 * @notice Pure storage contract for agent work attestations
 * @dev Minimal surface - no coordination logic, no scoring
 */
contract AttestationRegistry is IAttestationRegistry {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private _nextAttestationId = 1;
    
    mapping(uint256 => Attestation) private _attestations;
    mapping(bytes32 => uint256[]) private _attestationsByTask;
    mapping(uint256 => uint256[]) private _attestationsByAgent;

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function submitAttestation(
        uint256 agentId,
        bytes32 taskId,
        uint16 codeQuality,
        uint16 clarity,
        uint16 timeliness
    ) external returns (uint256 attestationId) {
        require(codeQuality <= 10, "Rating must be 0-10");
        require(clarity <= 10, "Rating must be 0-10");
        require(timeliness <= 10, "Rating must be 0-10");
        
        attestationId = _nextAttestationId++;
        
        Attestation memory attestation = Attestation({
            agentId: agentId,
            taskId: taskId,
            codeQuality: codeQuality,
            clarity: clarity,
            timeliness: timeliness,
            attester: msg.sender,
            timestamp: uint64(block.timestamp)
        });
        
        _attestations[attestationId] = attestation;
        _attestationsByTask[taskId].push(attestationId);
        _attestationsByAgent[agentId].push(attestationId);
        
        emit AttestationSubmitted(agentId, taskId, attestationId, msg.sender);
        
        return attestationId;
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAttestationsByTask(bytes32 taskId)
        external
        view
        returns (Attestation[] memory attestations)
    {
        uint256[] memory ids = _attestationsByTask[taskId];
        attestations = new Attestation[](ids.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            attestations[i] = _attestations[ids[i]];
        }
        
        return attestations;
    }

    function getAttestationsByAgent(uint256 agentId)
        external
        view
        returns (Attestation[] memory attestations)
    {
        uint256[] memory ids = _attestationsByAgent[agentId];
        attestations = new Attestation[](ids.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            attestations[i] = _attestations[ids[i]];
        }
        
        return attestations;
    }

    function getAttestation(uint256 attestationId)
        external
        view
        returns (Attestation memory attestation)
    {
        return _attestations[attestationId];
    }

    function totalAttestations() external view returns (uint256) {
        return _nextAttestationId - 1;
    }
}
