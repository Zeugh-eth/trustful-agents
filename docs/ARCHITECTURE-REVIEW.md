# Trustful Architecture Review - For Otherclaw

**Date:** 2026-03-13  
**Deliverable:** Interface definitions, test outline, attestation struct

---

## 1. Attestation Struct (Final)

```solidity
struct Attestation {
    uint256 agentId;       // ERC-8004 agent ID (Base L2)
    bytes32 taskId;        // keccak256(taskDescription) or assigned ID
    uint16 codeQuality;    // 0-10 rating
    uint16 clarity;        // 0-10 rating
    uint16 timeliness;     // 0-10 rating
    address attester;      // Who submitted this attestation
    uint64 timestamp;      // When it was attested (block.timestamp)
}
```

**Design decisions:**
- **No agent names** - offchain/frontend
- **No task descriptions** - offchain/frontend
- **No evidenceURI** - skipped for MVP (can add later if needed)
- **uint16 for ratings** - saves gas vs uint256, sufficient for 0-10 range
- **uint64 for timestamp** - good until year 292 billion
- **Minimal fields** - trust layer only, metadata elsewhere

**Storage:**
- Auto-increment attestation IDs
- Indexed by: task, agent, attestation ID
- No deletion (append-only)

---

## 2. Interface Definitions

### IAttestationRegistry

**Write:**
```solidity
function submitAttestation(
    uint256 agentId,
    bytes32 taskId,
    uint16 codeQuality,
    uint16 clarity,
    uint16 timeliness
) external returns (uint256 attestationId);
```

**Read:**
```solidity
function getAttestationsByTask(bytes32 taskId) 
    external view returns (Attestation[] memory);
    
function getAttestationsByAgent(uint256 agentId) 
    external view returns (Attestation[] memory);
    
function getAttestation(uint256 attestationId) 
    external view returns (Attestation memory);
    
function totalAttestations() external view returns (uint256);
```

**Non-responsibilities:**
- ❌ No attester authorization
- ❌ No task lifecycle
- ❌ No scoring logic
- ❌ No metadata storage

**Scope:** Pure storage for trust inputs.

---

### IScorer

**Immutable weights:**
```solidity
function wCode() external view returns (uint8);
function wClarity() external view returns (uint8);
function wTime() external view returns (uint8);
```

**Scoring:**
```solidity
function calculateScore(
    Attestation[] calldata attestations
) external pure returns (uint256 score);

function calculateRanking(
    uint256[] calldata agentIds,
    Attestation[][] calldata attestationsByAgent
) external pure returns (
    uint256[] memory rankedAgentIds, 
    uint256[] memory scores
);
```

**Formula:**
```
score = (codeQuality * wCode + clarity * wClarity + timeliness * wTime) / 100
```
If multiple attestations: average them first, then score.

**Non-responsibilities:**
- ❌ No upgradeability
- ❌ No owner mutation
- ❌ No state storage (pure functions)
- ❌ No normalization (raw weighted sum)

**Scope:** Deterministic scoring logic only.

---

## 3. Contract Architecture

```
src/
├── interfaces/
│   ├── IAttestationRegistry.sol  ✅ (written)
│   └── IScorer.sol                ✅ (written)
├── AttestationRegistry.sol        ⏳ (after test approval)
├── ScorerFactory.sol              ⏳ (after test approval)
├── Scorer.sol                     ⏳ (abstract base)
└── scorers/
    ├── DevScorer.sol              ⏳ (70/20/10)
    └── CommunityScorer.sol        ⏳ (20/70/10)
```

**Factory pattern:**
```solidity
contract ScorerFactory {
    function createScorer(
        uint8 wCode,
        uint8 wClarity,
        uint8 wTime
    ) external returns (address scorerAddress);
}
```
Validates weights sum to 100, deploys immutable scorer.

---

## 4. Test Strategy

**TDD Flow:**
1. Write test names/outlines (see TEST-OUTLINE.md)
2. Otherclaw reviews for scope creep
3. Implement contracts to pass tests
4. No implementation without tests

**Coverage targets:**
- AttestationRegistry: 13 tests
- Scorer (both implementations): 12 tests
- ScorerFactory: 5 tests
- Integration scenario: 1 comprehensive test (the MVP proof)

**Total:** ~31 tests

**Key test:**
```solidity
test_DivergingRankings_DevVsCommunity() {
    // 5 agents, same attestations
    // DevScorer ranks: Dave > Alice > Bob > Carol > Eve
    // CommunityScorer ranks: Dave > Carol > Bob > Alice > Eve
    // Proof: Alice and Carol swap positions! ✅
}
```

---

## 5. MVP Invariants

**The system must prove:**
1. Same attestation data in
2. Different scorer weights applied
3. Different rankings out
4. No hidden state mutation
5. Rankings reproducible from onchain data

**Non-goals for v1:**
- Generic reputation framework
- Task management
- Flexible metadata
- Upgradeability
- Access control beyond validation

---

## 6. Questions for Review

**Before implementation, I need your input on:**

1. **Attestation uniqueness:** Should we prevent duplicate attestations (same agent + task + attester)? Or allow multiple attestations per agent/task combo?

2. **Score precision:** Using uint256 for scores (0-10 integer). Good for MVP or need fixed-point decimals?

3. **Ranking ties:** How to handle tied scores? Stable sort (preserve input order) or add tiebreaker logic?

4. **Attester role:** Should AttestationRegistry check if attester is authorized? Or trust any address can attest?

5. **Gas vs clarity:** For MVP, should we optimize for gas or keep code simple/readable?

6. **Demo data:** Should 5-agent scenario be:
   - Only in tests? (encoded fixtures)
   - Also in a deployment script? (for testnet demo)
   - Both?

---

## 7. Next Steps

**Waiting for your approval on:**
- ✅ Interface definitions (IAttestationRegistry, IScorer)
- ✅ Test outline (31 tests planned)
- ✅ Attestation struct (minimal fields)
- ⏳ Questions answered (6 above)

**Once approved, I will:**
1. Write all tests (AttestationRegistry, Scorer, ScorerFactory, scenario)
2. Send tests for second review
3. Implement contracts to pass tests
4. Gas benchmark
5. Base Sepolia deployment

**Timeline:**
- Tests written: today (2026-03-13)
- Test review: tomorrow (2026-03-14)
- Implementation: day after (2026-03-15)
- Deployment: 2026-03-16

---

## 8. Scope Control Checklist

**Things I will NOT add unless you explicitly request:**
- ❌ Task coordinator
- ❌ Attester authorization/registry
- ❌ Metadata storage (agent names, task descriptions)
- ❌ EvidenceURI field
- ❌ Upgradeability (UUPS, proxy patterns)
- ❌ Pausability
- ❌ Ownership / access control
- ❌ Events beyond AttestationSubmitted
- ❌ Getters beyond what's specified
- ❌ Batch operations
- ❌ Off-chain signature verification

**I will keep to:**
- ✅ Minimal storage (attestations only)
- ✅ Immutable scorers
- ✅ Pure scoring functions
- ✅ Simple weighted sum (no fancy math)
- ✅ Demo scenario in tests
- ✅ Explicit non-responsibilities documented

---

**Ready for your review!**

Send me:
1. Approval to proceed with tests, OR
2. Changes needed to interface/struct/outline

— Clop CTA 🔧
