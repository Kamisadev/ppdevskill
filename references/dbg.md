# `#dbg` — Debug

Gated steps, in order (GATE 1 → 1.2 → 1.3 → 1.4 → 1.5). No skipping, no reordering. The mantra is title-only so it stays scannable and recitable; the body of each step carries the detail — read the step, not just the title.

Recite this mantra verbatim once per session (user says "skip the mantra" → apply silently):
> 1. **Reproducibility first** — can the issue be reproduced reliably?
> 2. **Know the fail path** — debugger first → source trace + knob enumeration → in-code instrumentation.
> 3. **Question your hypothesis** — what would disprove it?
> 4. **Every run is a breadcrumb** — cross-reference all of them.
> 5. **Check the plug before the logic** — observing the real system, not a stale build / wrong env?
> 6. **Shrink the repro to the bone** — cut until one more cut makes it pass; the residue is the cause.
> 7. **Binary-search the fault** — probe the midpoint, discard half; bisect, never linear-scan.
> 8. **Fix the cause, not the symptom** — patch where the invariant breaks, not where it surfaces.
> 9. **Toggle the fix, prove causality both ways** — fix → green AND revert → red, else coincidence.

## GATE 1 — Reliable Repro (before anything else)

| Status | Action |
|---|---|
| Reliable | Capture as runnable artifact (failing test / curl / CLI / replay) → STEP 1.2 |
| Flaky | Not debuggable yet. Raise the rate (loop, parallelize, stress, narrow timing) to ≥50%, then proceed. |
| No repro | **Full stop.** Say so. Ask for env access / artifacts (HAR, log, core) / permission to instrument. Do not guess. Do not hypothesize. |

Target: fast (1–5s), deterministic pass/fail. Pin time, seed RNG, freeze network. Proposing a fix without a reliable repro is a violation — return to this gate.

**Shrink to the bone (mantra 6).** Reliable ≠ minimal — a repro can be 500 lines of noise and still pass this gate. Once it repros, cut inputs, steps, and config one at a time until one more cut makes it pass; what remains IS the cause, and it becomes the regression test in STEP 1.5. Reduce before you read source: a minimal artifact collapses the suspect space and sharpens every disproof in 1.3.

## PARTNER CALL — Pattern Recognition (after GATE 1)

Symptom resembles a known failure class → call it: one sentence what it looks like, one where to look (e.g. *"Intermittent + load-dependent + passes in isolation = race condition writing shared state without a lock. Check [X] first."*). No match → *"No pattern match yet; need to trace the fail path first."* A pattern call is a hypothesis for 1.3, not a conclusion.

## STEP 1.2 — Know the Fail Path

**Check the plug first (mantra 5).** Before tracing anything, confirm you are observing the real system: the build actually ran, the live binary / branch / env / dependency / input is the one you think it is, no stale artifact or wrong venv. When the trace contradicts your mental model, suspect the observation surface before rewriting the model — the data is rarely the liar. Debugging code that never executed is the most expensive waste there is.

**Binary-search the fault (mantra 7).** Over any *ordered* range — commits, input size, the call path — probe the midpoint and let each result discard half (O(log n), not linear). `git bisect` a regression down to the breaking commit; wolf-fence a pipeline; halve the input. This picks *where* on the path to look; knob enumeration below picks *what* to vary once you are there.

Escalate in order; document why each escalation was needed. Do not jump to 3 if 1 is available.
1. **Debugger** — step to the failure site (one breakpoint beats ten logs).
2. **Source trace + knob enumeration** — walk the code path end-to-end; list every knob (config, env, toggle, branch, input shape, timing, concurrency); flip one at a time.
3. **In-code instrumentation** — only if knobs cannot move the failure. Tag each probe with a unique prefix (e.g. `[DBG-a4f2]`) for clean removal later.

## STEP 1.3 — Falsify the Hypothesis

Generate **3–5 ranked hypotheses**, not one. Each must explain the symptom end-to-end — walk it through. Find the simplest proof AND disproof for each → **run the disproof first.** Survives = real; dies = five hours saved. No fix committed until a hypothesis survives disproof.

## STEP 1.4 — Breadcrumb Ledger

Session ledger: each entry = what changed, what happened, what it ruled in/out. **Persist to `.ppdev/dbg-ledger.md`** — not just chat context; it survives compaction, so re-anchor from the file, not memory.
- New hypothesis → must hold for every prior observation; contradiction → refine or discard.
- Stuck → design the **single experiment** whose outcome resolves the ambiguity; run that next.

## STEP 1.5 — Fix at the Cause, Prove Both Ways

Only after a hypothesis survives 1.3 disproof. Diagnosis (1.2) found *where the bug lives*; this step decides *where the edit lands* and *whether it actually worked*.
- **Fix the cause, not the symptom (mantra 8).** Patch where the invariant first breaks, not where it surfaces. A null-check, clamp, retry, or try/catch wrapped around a bad value is usually a coverup — the mechanism is still alive upstream and resurfaces elsewhere. If you cannot name the invariant being restored, you have not found the cause yet. (A guard IS the right fix when "absent/invalid" is a legitimate state — e.g. stale token → 401; the test is whether you are restoring an invariant or hiding a violation.)
- **Toggle the fix, prove causality both ways (mantra 9).** The fix makes the repro green AND reverting the fix makes it red again — one direction alone admits a flaky or coincidental green. Capture this as a regression test you watched FAIL for the right reason *before* it passed; that automated guard outlives the manual GATE 1 repro and pins the bug class shut.

## HARD RULES

Mantra once per session, verbatim · steps 1→2→3→4→5 · no fix proposed until GATE 1 passes · no hypothesis testing until 1.2 narrows the path · no hypothesis committed until 1.3 disproof attempt · caught proposing a fix without repro → return to GATE 1 · fix lands at the cause, not the symptom (1.5) · **after applying any fix: rerun the GATE 1 repro and see it pass AND revert-to-confirm it fails again (mantra 9), plus the verify recipe (`references/verify.md`)** — green output is done; "the fix should work" is not.
