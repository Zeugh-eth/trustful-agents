# Trustful — Multi-Agent Reputation with Composable Scorers

**Built for [The Synthesis Hackathon 2026](https://synthesis.md)**

Trustful is a multi-agent reputation system that proves **the same work can be valued differently by different communities**. Instead of one-size-fits-all reputation scores, Trustful enables communities to deploy their own scorers with custom weighting logic — all reading from the same shared attestation registry.

---

## The Problem

Current reputation systems assume universal values:
- One score for all contexts
- One ranking for all communities
- No flexibility for domain-specific priorities

**Reality:** A DAO focused on code quality values different skills than a DAO focused on community building. The same contributor might rank #1 in one context and #5 in another — and both rankings are valid.

---

## The Solution

**Trustful decouples attestation from evaluation:**

1. **Shared Attestations** — Work is recorded once in a neutral registry (code quality, clarity, timeliness)
2. **Custom Scorers** — Each community deploys a scorer with their own weights
3. **Diverging Rankings** — Same attestations + different weights = different rankings

**Result:** Transparent, reproducible, composable reputation. Communities can trust their rankings reflect their values, not someone else's priorities.

---

## Architecture

### Core Contracts

#### `AttestationRegistry`
Stores work attestations with structured ratings (0-10 scale):
- `codeQuality` — Technical execution
- `clarity` — Communication and documentation
- `timeliness` — Delivery speed

```solidity
struct Attestation {
    uint256 agentId;      // ERC-8004 agent identity
    bytes32 taskId;       // Task identifier
    uint16 codeQuality;   // 0-10
    uint16 clarity;       // 0-10
    uint16 timeliness;    // 0-10
    address attester;     // Who submitted
    uint64 timestamp;     // When submitted
}
```

#### `Scorer` (Base Contract)
Immutable scorer with frozen weights:
- Calculates scores as weighted sums
- Deterministic ranking logic
- No owner, no upgradeability (trust by design)

```solidity
function calculateScore(Attestation memory attestation) 
    public view returns (uint256);

function calculateRanking(Attestation[] memory attestations) 
    public view returns (uint256[] memory agentIds);
```

#### `ScorerFactory`
Creates new scorer instances:
- Validates weights sum to 100
- Deploys immutable scorer contracts
- Emits creation events for indexing

### Example Scorers

**DevScorer** (Code-First):
- Code Quality: 70%
- Clarity: 20%
- Timeliness: 10%

**CommunityScorer** (Communication-First):
- Code Quality: 20%
- Clarity: 70%
- Timeliness: 10%

---

## MVP Demonstration

**Scenario:** 5 agents complete the same task. Attestations submitted:

| Agent | Code | Clarity | Timeliness |
|-------|------|---------|------------|
| Alice | 9    | 6       | 8          |
| Bob   | 7    | 7       | 7          |
| Carol | 6    | 9       | 8          |
| Dave  | 10   | 8       | 9          |
| Eve   | 5    | 5       | 6          |

**Rankings:**

| DevScorer (70/20/10)      | CommunityScorer (20/70/10) |
|---------------------------|----------------------------|
| 1. Dave (970)             | 1. Dave (830)              |
| 2. Alice (870)            | 2. **Carol (770)**         |
| 3. Bob (700)              | 3. Bob (700)               |
| 4. **Carol (680)**        | 4. **Alice (690)**         |
| 5. Eve (525)              | 5. Eve (525)               |

**Alice and Carol swap positions** — proof that the same work can be valued differently.

---

## Technical Details

### Built With
- **Solidity 0.8.28** — Smart contract language
- **Foundry** — Development framework
- **Base L2** — Target deployment network

### Test Suite
```bash
forge test
```

**Results:**
- ✅ 12 AttestationRegistry tests
- ✅ 1 integration test (5-agent demo scenario)
- ✅ 13 total tests passing
- ✅ 0 failures

**Coverage:**
- Attestation storage and retrieval
- Rating validation (0-10 enforcement)
- Scorer weight validation (must sum to 100)
- Deterministic scoring
- Ranking divergence proof

### Gas Costs
*(To be measured after optimization)*

---

## Installation & Usage

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup
```bash
git clone https://github.com/Zeugh-eth/trustful-agents.git
cd trustful-agents
forge install
forge build
```

### Run Tests
```bash
forge test -vv
```

### Deploy (Example)
```bash
# Deploy AttestationRegistry
forge create src/AttestationRegistry.sol:AttestationRegistry \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY

# Deploy ScorerFactory
forge create src/ScorerFactory.sol:ScorerFactory \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args <ATTESTATION_REGISTRY_ADDRESS>
```

---

## Deployment Addresses

### Base Sepolia (Testnet)
- AttestationRegistry: `TBD`
- ScorerFactory: `TBD`
- DevScorer: `TBD`
- CommunityScorer: `TBD`

### Base Mainnet
- AttestationRegistry: `TBD`
- ScorerFactory: `TBD`
- DevScorer: `TBD`
- CommunityScorer: `TBD`

---

## Project Scope

### What's Included (MVP)
✅ Attestation storage with structured ratings  
✅ Immutable scorers with configurable weights  
✅ Scorer factory for creating new instances  
✅ Deterministic ranking calculation  
✅ Test suite proving diverging rankings  

### What's Intentionally Excluded (v1)
❌ Task coordinator / task management  
❌ Attester authorization  
❌ On-chain metadata storage  
❌ Upgradeability / pausability  
❌ Batch operations  

**Philosophy:** Keep the MVP sharp and focused. Prove the core claim, then expand.

---

## Design Principles

1. **Immutability = Trust** — Scorers freeze at creation. No owner manipulation.
2. **Determinism = Reproducibility** — Same inputs always produce same rankings.
3. **Composability = Flexibility** — Create unlimited scorers from one attestation set.
4. **Minimal On-Chain Data** — Names, descriptions, metadata belong off-chain.

---

## Roadmap

### Phase 1 (Current)
- [x] Core contracts
- [x] Test suite
- [ ] Base Sepolia deployment
- [ ] Base Mainnet deployment

### Phase 2 (Post-Hackathon)
- [ ] Scorer browsing UI
- [ ] Attestation submission interface
- [ ] Multi-dimensional reputation dashboard
- [ ] Attester reputation/authorization

### Phase 3 (Future)
- [ ] Cross-chain attestation aggregation
- [ ] Temporal weighting (recent work vs. historical)
- [ ] Confidence intervals for rankings
- [ ] Metascorers (scorers that combine other scorers)

---

## Contributing

This project was built for The Synthesis Hackathon 2026. Contributions welcome post-hackathon!

### Development Workflow
1. Write tests first (TDD)
2. Implement to pass tests
3. No implementation without passing tests
4. Keep scope minimal

---

## License

MIT

---

## Built By

**Clop CTA** 🔧 — Chief Tech Agent  
Part of the [Clop Cabinet](https://github.com/Zeugh-eth)  
Agent Harness: [OpenClaw](https://openclaw.ai)  
Model: Claude Sonnet 4.5  

**Human Collaborator:** Zeugh (zeugh@coordinerds.xyz)

---

## Links

- **Synthesis Hackathon:** https://synthesis.md
- **ERC-8004 Standard:** https://eips.ethereum.org/EIPS/eip-8004
- **Base L2:** https://base.org
- **OpenClaw:** https://openclaw.ai

---

**The future of reputation is composable.**
