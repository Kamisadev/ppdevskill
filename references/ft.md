# `#ft` — Feature

The job is not closing the ticket. It is delivering what the user actually needs, and that holds in production.

## GATE 2 — Three preconditions (all required before any implementation)

- [ ] **Real need understood** — state the user's actual goal in their own words (not the technical request reframed). Request and real need diverge → surface first: *"You asked for X, but the real need appears to be Y — confirm before I build?"*
- [ ] **Acceptance criteria as testable scenarios** — minimum 3, shape *"given X, when Y, then Z."* Cannot write 3 → requirement not ready; return to the user.
- [ ] **Scope bounded** — what is IN and what is OUT, with rationale (the OUT list usually matters more).
- [ ] **Abuse case (if the feature touches a trust boundary)** — ≥1 scenario in shape *"given a malicious actor, when X, then the system must NOT Y."* New input path / auth / file / query / external call → mandatory; Read `references/sec.md` for triggers + templates. No boundary touched → state that in one line.

Five minutes asking beats five hours coding the wrong thing.

## PARTNER CALL — Brief Interrogation (after GATE 2)

Answer these yourself first; surface any with a bad answer before building:
1. **What breaks if this is wrong?** — data loss? bad UX? silent failure? "Nothing serious" changes the build discipline.
2. **What is the failure mode nobody wrote down?** — name the edge case that looks fine but isn't.
3. **Is there a simpler version covering 80% of the value?** — if yes: *"You asked for X; a simpler version handling the core case is Y. Works? Here is what it leaves out."*

## STEP 2.1 — Understand the Real Need

State the actual goal in the user's own words · ask what happens if we do nothing ("minor inconvenience" → reconsider lifetime maintenance cost) · ask what they want one level above the stated request · divergence → surface and stop; do not quietly redesign.

## STEP 2.2 — Design the Contract (before any implementation)

- **API surface** — smallest interface that does the job.
- **Success contract** — input X → output Y, concrete examples.
- **Failure contract** — throw / null / retry / degrade / timeout. Part of the API, not an afterthought. Covers **malicious** input (injection, oversized, forged token), not only honest-but-malformed input — see `references/sec.md`.
- **Edge cases** — empty, null, huge, unicode, concurrent, partial state, duplicate, network flap, expired session. Explicit list, not discovered in production.
- **Observability** — which metrics/logs/traces, designed in.
- **Integration** — which contracts it touches; does it break any caller?

Cannot write the contract → requirement not ready; return to STEP 2.1.

## STEP 2.3 — Make the Change Easy First

Trace the existing path end-to-end; find the seam where the new behavior plugs in. Seam missing → **hand off to `#rf` first** (separate diff), then return. *"Make the change easy, then make the easy change."*

## STEP 2.4 — Build Incrementally, Prove Each Step

Smallest viable slice first ("implement the entire feature" is not a slice) · test order: happy → error → edge, all three before "done" (error paths are not optional polish) · each commit independently green and revertable · no "test it later" · verify against the GATE 2 acceptance criteria, not a feeling of "seems done."

## STEP 2.5 — Verify in Runtime Before "Done"

Execute the recipe for the work type from `references/verify.md` (Read it now if not already) and report observed output per the verification block rule. Static checks never count.

## HARD RULES

GATE 2 before any implementation · YAGNI, no premature abstraction (rule of three) · error paths get equal care · no "while I'm here" additions — spot a bug, file it · scope grows mid-build → stop, re-confirm · **done = code written + verify recipe executed and reported + tests green + observable + reviewed** — "feature works" / "looks correct" / "should work" are not verifications; running it is · the user is not the test environment.
