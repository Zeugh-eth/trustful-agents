// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAttestationRegistry
 * @notice Pure storage contract for agent work attestations
 * @dev Minimal surface: no coordination logic, no scoring
 */
interface IAttestationRegistry {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Single attestation of agent work quality
     * @dev All ratings are 0-10 uint16, attested by a trusted address
     * @param agentId ERC-8004 agent identifier (Base L2)
     * @param taskId Unique task identifier (keccak256 hash)
     * @param codeQuality Rating 0-10 for code/implementation quality
     * @param clarity Rating 0-10 for communication/documentation
     * @param timeliness Rating 0-10 for delivery speed
     * @param attester Address that submitted this attestation
     * @param timestamp Block timestamp when attested
     */
    struct Attestation {
        uint256 agentId;
        bytes32 taskId;
        uint16 codeQuality;    // 0-10
        uint16 clarity;        // 0-10
        uint16 timeliness;     // 0-10
        address attester;
        uint64 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AttestationSubmitted(
        uint256 indexed agentId,
        bytes32 indexed taskId,
        uint256 indexed attestationId,
        address attester
    );

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Submit a new attestation for agent work
     * @dev Validates ratings are 0-10, stores with auto-increment ID
     * @param agentId ERC-8004 agent ID
     * @param taskId Unique task identifier
     * @param codeQuality Code quality rating (0-10)
     * @param clarity Communication clarity rating (0-10)
     * @param timeliness Delivery timeliness rating (0-10)
     * @return attestationId Unique ID for this attestation
     */
    function submitAttestation(
        uint256 agentId,
        bytes32 taskId,
        uint16 codeQuality,
        uint16 clarity,
        uint16 timeliness
    ) external returns (uint256 attestationId);

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get all attestations for a specific task
     * @param taskId Task identifier
     * @return attestations Array of attestations for this task
     */
    function getAttestationsByTask(bytes32 taskId)
        external
        view
        returns (Attestation[] memory attestations);

    /**
     * @notice Get all attestations for a specific agent
     * @param agentId ERC-8004 agent ID
     * @return attestations Array of attestations for this agent
     */
    function getAttestationsByAgent(uint256 agentId)
        external
        view
        returns (Attestation[] memory attestations);

    /**
     * @notice Get a single attestation by ID
     * @param attestationId Unique attestation ID
     * @return attestation The attestation struct
     */
    function getAttestation(uint256 attestationId)
        external
        view
        returns (Attestation memory attestation);

    /**
     * @notice Get total number of attestations
     * @return Total attestations submitted
     */
    function totalAttestations() external view returns (uint256);
}
