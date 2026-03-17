# Trustful Test Outline

## Test Strategy

**TDD Workflow:**
1. Write tests first (define behavior)
2. Send to otherclaw for architecture review
3. Implement contracts to pass tests
4. No implementation without passing tests

**Goal:** Prove that same attestations + different scorer weights = different rankings

---

## AttestationRegistry Tests

### File: `test/AttestationRegistry.t.sol`

**Unit Tests:**
- `test_SubmitAttestation_StoresCorrectly()` - Basic storage
- `test_SubmitAttestation_EmitsEvent()` - Event emission
- `test_SubmitAttestation_AutoIncrementId()` - Sequential IDs
- `test_SubmitAttestation_RevertsIfInvalidRating()` - Reject ratings > 10
- `test_GetAttestationsByTask_ReturnsAll()` - Task filtering
- `test_GetAttestationsByAgent_ReturnsAll()` - Agent filtering
- `test_GetAttestation_ReturnsSingle()` - ID lookup
- `test_TotalAttestations_Increments()` - Counter accuracy

**Edge Cases:**
- `test_EmptyTask_ReturnsEmptyArray()` - No attestations for task
- `test_EmptyAgent_ReturnsEmptyArray()` - No attestations for agent
- `test_MultipleAttestations_SameAgent()` - Same agent, different tasks
- `test_MultipleAttestations_SameTask()` - Multiple agents, same task

**Invariants:**
- Attestation IDs never decrease
- Ratings always 0-10
- Timestamp always >= block.timestamp at submission
- Total attestations == max attestation ID

---

## Scorer Tests

### File: `test/Scorer.t.sol`

**Abstract Base Tests (if we have one):**
- `test_Constructor_ValidatesWeights()` - Weights must sum to 100
- `test_Constructor_RevertsInvalidWeights()` - Reject if sum != 100
- `test_Weights_AreImmutable()` - Can't change after deployment

**DevScorer Tests:** (weights: code 70%, clarity 20%, time 10%)
- `test_DevScorer_WeightsCorrect()` - Verify 70/20/10
- `test_DevScorer_ScoresHighCodeQuality()` - Alice (9,4,8) > Carol (3,9,8)
- `test_DevScorer_Deterministic()` - Same inputs = same outputs
- `test_DevScorer_HandlesZeroAttestations()` - Return 0 for empty array
- `test_DevScorer_AveragesMultipleAttestations()` - Mean of all attestations

**CommunityScorer Tests:** (weights: code 20%, clarity 70%, time 10%)
- `test_CommunityScorer_WeightsCorrect()` - Verify 20/70/10
- `test_CommunityScorer_ScoresHighClarity()` - Carol (3,9,8) > Alice (9,4,8)
- `test_CommunityScorer_Deterministic()` - Same inputs = same outputs

**Ranking Tests:**
- `test_CalculateRanking_SortsDescending()` - Highest score first
- `test_CalculateRanking_HandlesTies()` - Stable sort for equal scores
- `test_CalculateRanking_EmptyArray()` - Return empty for no agents

---

## ScorerFactory Tests

### File: `test/ScorerFactory.t.sol`

**Creation Tests:**
- `test_CreateScorer_DeploysNewContract()` - Returns valid address
- `test_CreateScorer_SetsWeightsCorrectly()` - Deployed scorer has correct weights
- `test_CreateScorer_RevertsInvalidWeights()` - Reject if weights don't sum to 100
- `test_CreateScorer_DifferentAddresses()` - Each scorer gets unique address

**Factory Tracking (if we add):**
- `test_GetScorer_ReturnsDeployed()` - Lookup by ID
- `test_TotalScorers_Increments()` - Counter accuracy

---

## Integration / Scenario Tests

### File: `test/scenarios/FiveAgentsDemoScenario.t.sol`

**The MVP Proof:**

```solidity
/**
 * @notice 5 agents complete same task, different skill profiles
 * Task: "Submit governance proposal for DAO treasury allocation"
 */
contract FiveAgentsDemoScenarioTest {
    // Alice: strong code, weak communication
    // Bob: balanced
    // Carol: strong communication, weak code  
    // Dave: strong everything
    // Eve: weak everything
    
    function test_DivergingRankings_DevVsCommunity() {
        // Submit attestations for all 5 agents
        // Alice: codeQuality=9, clarity=4, timeliness=8
        // Bob: codeQuality=6, clarity=6, timeliness=7
        // Carol: codeQuality=3, clarity=9, timeliness=8
        // Dave: codeQuality=9, clarity=9, timeliness=9
        // Eve: codeQuality=2, clarity=3, timeliness=5
        
        // Create DevScorer (70/20/10)
        // Create CommunityScorer (20/70/10)
        
        // Calculate rankings
        // DevScorer: Dave > Alice > Bob > Carol > Eve
        // CommunityScorer: Dave > Carol > Bob > Alice > Eve
        
        // Assert: Alice and Carol swap positions (PROOF!)
        assertEq(devRanking[1], ALICE);
        assertEq(communityRanking[1], CAROL);
    }
}
```

**Key Assertions:**
- Same attestation data for both scorers
- Rankings differ visibly (Alice/Carol swap)
- Dave always first (strong everything)
- Eve always last (weak everything)
- No ties in this scenario

---

## Coverage Goals

- **Line coverage:** 100% (small surface)
- **Branch coverage:** 100% (minimal branching)
- **Mutation score:** High (tests should catch logic errors)

---

## Gas Benchmarks

Track gas costs for:
- `submitAttestation()` - Target: <50k gas
- `calculateScore()` - Target: <100k gas for 5 attestations
- `calculateRanking()` - Target: <200k gas for 5 agents

---

## What's NOT Tested (Intentionally Out of Scope)

❌ Task coordination / lifecycle  
❌ Attester authorization  
❌ Metadata storage  
❌ Scorer upgradeability  
❌ Governance / ownership  
❌ Pausability  
❌ Access control beyond basic validation

**Why:** MVP proof, not production protocol.

---

## Questions for Otherclaw

1. **Attestation uniqueness:** Should we prevent duplicate attestations (same agent + task + attester)? Or allow multiple?

2. **Score precision:** uint256 for scores works, but do we want fixed-point for sub-integer precision? Or keep integer 0-10?

3. **Ranking ties:** Stable sort (preserve input order) or secondary tiebreaker?

4. **Gas optimization:** Is gas a priority for MVP, or clarity > gas?

5. **Demo data:** Should demo scenario be encoded in tests, or also as a deployment script?
