// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AttestationRegistry} from "../../src/AttestationRegistry.sol";
import {IAttestationRegistry} from "../../src/interfaces/IAttestationRegistry.sol";
import {DevScorer} from "../../src/scorers/DevScorer.sol";
import {CommunityScorer} from "../../src/scorers/CommunityScorer.sol";

/**
 * @title FiveAgentsDemoScenarioTest
 * @notice THE MVP PROOF - Same attestations + different scorers = different rankings
 */
contract FiveAgentsDemoScenarioTest is Test {
    AttestationRegistry public registry;
    DevScorer public devScorer;
    CommunityScorer public communityScorer;
    
    uint256 constant ALICE = 1; // Strong code, weak communication
    uint256 constant BOB = 2;   // Balanced
    uint256 constant CAROL = 3; // Strong communication, weak code
    uint256 constant DAVE = 4;  // Strong everything
    uint256 constant EVE = 5;   // Weak everything
    
    bytes32 constant TASK = keccak256("Governance Proposal");
    
    function setUp() public {
        registry = new AttestationRegistry();
        devScorer = new DevScorer();
        communityScorer = new CommunityScorer();
        
        // Submit attestations for all 5 agents (same task)
        // Alice: code=9, clarity=4, time=8
        registry.submitAttestation(ALICE, TASK, 9, 4, 8);
        
        // Bob: code=6, clarity=6, time=7  
        registry.submitAttestation(BOB, TASK, 6, 6, 7);
        
        // Carol: code=3, clarity=9, time=8
        registry.submitAttestation(CAROL, TASK, 3, 9, 8);
        
        // Dave: code=9, clarity=9, time=9
        registry.submitAttestation(DAVE, TASK, 9, 9, 9);
        
        // Eve: code=2, clarity=3, time=5
        registry.submitAttestation(EVE, TASK, 2, 3, 5);
    }
    
    function test_DivergingRankings_DevVsCommunity() public {
        uint256[] memory agentIds = new uint256[](5);
        agentIds[0] = ALICE;
        agentIds[1] = BOB;
        agentIds[2] = CAROL;
        agentIds[3] = DAVE;
        agentIds[4] = EVE;
        
        IAttestationRegistry.Attestation[][] memory attestationsByAgent = 
            new IAttestationRegistry.Attestation[][](5);
        
        for (uint256 i = 0; i < 5; i++) {
            attestationsByAgent[i] = registry.getAttestationsByAgent(agentIds[i]);
        }
        
        // Calculate rankings with DevScorer (70% code, 20% clarity, 10% time)
        (uint256[] memory devRanking, uint256[] memory devScores) = 
            devScorer.calculateRanking(agentIds, attestationsByAgent);
        
        // Calculate rankings with CommunityScorer (20% code, 70% clarity, 10% time)
        (uint256[] memory communityRanking, uint256[] memory communityScores) = 
            communityScorer.calculateRanking(agentIds, attestationsByAgent);
        
        // Verify scores
        console.log("=== DEV SCORER (70/20/10) ===");
        for (uint256 i = 0; i < 5; i++) {
            console.log("Agent:", devRanking[i], "Score:", devScores[i]);
        }
        
        console.log("=== COMMUNITY SCORER (20/70/10) ===");
        for (uint256 i = 0; i < 5; i++) {
            console.log("Agent:", communityRanking[i], "Score:", communityScores[i]);
        }
        
        // MVP PROOF: Rankings must differ
        // DevScorer should rank: Dave > Alice > Bob > Carol > Eve
        assertEq(devRanking[0], DAVE, "Dev: Dave should be 1st");
        assertEq(devRanking[1], ALICE, "Dev: Alice should be 2nd");
        assertEq(devRanking[4], EVE, "Dev: Eve should be last");
        
        // CommunityScorer should rank: Dave > Carol > Bob > Alice > Eve  
        assertEq(communityRanking[0], DAVE, "Community: Dave should be 1st");
        assertEq(communityRanking[1], CAROL, "Community: Carol should be 2nd");
        assertEq(communityRanking[4], EVE, "Community: Eve should be last");
        
        // THE PROOF: Alice and Carol swap positions!
        assertTrue(devRanking[1] == ALICE && communityRanking[1] == CAROL, 
            "PROOF FAILED: Alice and Carol should swap between scorers!");
        
        console.log("MVP PROOF VERIFIED: Same attestations + different weights = different rankings!");
    }
}
