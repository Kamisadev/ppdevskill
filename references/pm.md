# `#pm` — Post-mortem

An engineering record of a fix, written **after** a validated fix lands, **for** other engineers and future-you.

## GATE 5 — Four required inputs (all before drafting)

- [ ] **Reliable repro** — the next person can run it.
- [ ] **Root cause known** — mechanism identified, not a hypothesis.
- [ ] **Fix identified** — PR / commit / branch.
- [ ] **Fix validated** — the original repro now passes.

A post-mortem of a hypothesis is worse than none. Any input missing → refuse, state what is missing.

## WHEN NOT TO DRAFT

Bug not fixed / not validated → refuse · customer-visible outage → a separate incident report is needed (timeline, blast radius, paging, comms); flag and confirm · trivial fix (typo) → the PR description is the record.

## STRUCTURE

**Summary, Root cause, Fix, Validation are mandatory.** The rest is conditional.
1. **Summary** *(must)* — one paragraph: what broke, what fixed it, ticket, PR, owner.
2. **Symptom** — what was observed: test output, error, log line, perf number.
3. **Root cause** *(must)* — the actual bug mechanism; code identifiers required; walk the cause chain end-to-end.
4. **Why it produced the symptom** — link cause to symptom (often non-obvious).
5. **Fix** *(must)* — what changed and why it addresses the root cause, not the symptom; a prior attempt papered over it → name it.
6. **How it was found** — repro, tools, hypotheses tried and rejected, the single confirming experiment.
7. **Why it slipped through** — CI gap, latent code, workload gap, incomplete prior fix, review miss. **Blameless** — the gap, not the person.
8. **Validation** *(must)* — concrete: test passes, perf before/after, stress run; only one config tested → say so explicitly.
9. **Action items** — what + owner + tracking artifact; none → "None — the fix is sufficient." Do not manufacture.

## HARD RULES

Refuse without all four inputs · never invent root cause / owner / validation runs / action items — ask · never strip code identifiers · blameless · state validation coverage honestly · sign-off before posting to any external system.
