// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AttestationRegistry} from "../src/AttestationRegistry.sol";
import {IAttestationRegistry} from "../src/interfaces/IAttestationRegistry.sol";

contract AttestationRegistryTest is Test {
    AttestationRegistry public registry;
    
    uint256 constant ALICE_AGENT_ID = 29072;
    uint256 constant BOB_AGENT_ID = 29073;
    bytes32 constant TASK_1 = keccak256("Governance Proposal");
    bytes32 constant TASK_2 = keccak256("Smart Contract Audit");
    
    address attester1 = address(0x1);
    address attester2 = address(0x2);

    function setUp() public {
        registry = new AttestationRegistry();
    }

    // Basic storage tests
    function test_SubmitAttestation_StoresCorrectly() public {
        vm.prank(attester1);
        uint256 id = registry.submitAttestation(
            ALICE_AGENT_ID,
            TASK_1,
            9, // codeQuality
            4, // clarity
            8  // timeliness
        );
        
        assertEq(id, 1, "First attestation should have ID 1");
        
        AttestationRegistry.Attestation memory att = registry.getAttestation(id);
        assertEq(att.agentId, ALICE_AGENT_ID);
        assertEq(att.taskId, TASK_1);
        assertEq(att.codeQuality, 9);
        assertEq(att.clarity, 4);
        assertEq(att.timeliness, 8);
        assertEq(att.attester, attester1);
        assertEq(att.timestamp, block.timestamp);
    }

    function test_SubmitAttestation_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IAttestationRegistry.AttestationSubmitted(ALICE_AGENT_ID, TASK_1, 1, attester1);
        
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
    }

    function test_SubmitAttestation_AutoIncrementId() public {
        vm.prank(attester1);
        uint256 id1 = registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        vm.prank(attester2);
        uint256 id2 = registry.submitAttestation(BOB_AGENT_ID, TASK_2, 6, 6, 7);
        
        assertEq(id1, 1);
        assertEq(id2, 2);
    }

    function test_SubmitAttestation_RevertsIfInvalidRating() public {
        vm.expectRevert("Rating must be 0-10");
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 11, 4, 8); // code > 10
        
        vm.expectRevert("Rating must be 0-10");
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 11, 8); // clarity > 10
        
        vm.expectRevert("Rating must be 0-10");
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 11); // time > 10
    }

    // Read function tests
    function test_GetAttestationsByTask_ReturnsAll() public {
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        vm.prank(attester2);
        registry.submitAttestation(BOB_AGENT_ID, TASK_1, 6, 6, 7);
        
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByTask(TASK_1);
        
        assertEq(attestations.length, 2);
        assertEq(attestations[0].agentId, ALICE_AGENT_ID);
        assertEq(attestations[1].agentId, BOB_AGENT_ID);
    }

    function test_GetAttestationsByAgent_ReturnsAll() public {
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        vm.prank(attester2);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_2, 8, 5, 9);
        
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByAgent(ALICE_AGENT_ID);
        
        assertEq(attestations.length, 2);
        assertEq(attestations[0].taskId, TASK_1);
        assertEq(attestations[1].taskId, TASK_2);
    }

    function test_GetAttestation_ReturnsSingle() public {
        vm.prank(attester1);
        uint256 id = registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        AttestationRegistry.Attestation memory att = registry.getAttestation(id);
        
        assertEq(att.agentId, ALICE_AGENT_ID);
        assertEq(att.taskId, TASK_1);
    }

    function test_TotalAttestations_Increments() public {
        assertEq(registry.totalAttestations(), 0);
        
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        assertEq(registry.totalAttestations(), 1);
        
        vm.prank(attester2);
        registry.submitAttestation(BOB_AGENT_ID, TASK_2, 6, 6, 7);
        assertEq(registry.totalAttestations(), 2);
    }

    // Edge cases
    function test_EmptyTask_ReturnsEmptyArray() public {
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByTask(TASK_1);
        assertEq(attestations.length, 0);
    }

    function test_EmptyAgent_ReturnsEmptyArray() public {
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByAgent(ALICE_AGENT_ID);
        assertEq(attestations.length, 0);
    }

    function test_MultipleAttestations_SameAgent() public {
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        vm.prank(attester2);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 8, 5, 7);
        
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByAgent(ALICE_AGENT_ID);
        assertEq(attestations.length, 2);
    }

    function test_MultipleAttestations_SameTask() public {
        vm.prank(attester1);
        registry.submitAttestation(ALICE_AGENT_ID, TASK_1, 9, 4, 8);
        
        vm.prank(attester1);
        registry.submitAttestation(BOB_AGENT_ID, TASK_1, 6, 6, 7);
        
        AttestationRegistry.Attestation[] memory attestations = registry.getAttestationsByTask(TASK_1);
        assertEq(attestations.length, 2);
    }
}
