# `#dbg` — Debug

Four steps, in order. No skipping, no reordering.

Recite this mantra verbatim once per session (user says "skip the mantra" → apply silently):
> 1. **Reproducibility first** — can the issue be reproduced reliably?
> 2. **Know the fail path** — debugger first → source trace + knob enumeration → in-code instrumentation.
> 3. **Question your hypothesis** — what would disprove it?
> 4. **Every run is a breadcrumb** — cross-reference all of them.

## GATE 1 — Reliable Repro (before anything else)

| Status | Action |
|---|---|
| Reliable | Capture as runnable artifact (failing test / curl / CLI / replay) → STEP 1.2 |
| Flaky | Not debuggable yet. Raise the rate (loop, parallelize, stress, narrow timing) to ≥50%, then proceed. |
| No repro | **Full stop.** Say so. Ask for env access / artifacts (HAR, log, core) / permission to instrument. Do not guess. Do not hypothesize. |

Target: fast (1–5s), deterministic pass/fail. Pin time, seed RNG, freeze network. Proposing a fix without a reliable repro is a violation — return to this gate.

## PARTNER CALL — Pattern Recognition (after GATE 1)

Symptom resembles a known failure class → call it: one sentence what it looks like, one where to look (e.g. *"Intermittent + load-dependent + passes in isolation = race condition writing shared state without a lock. Check [X] first."*). No match → *"No pattern match yet; need to trace the fail path first."* A pattern call is a hypothesis for 1.3, not a conclusion.

## STEP 1.2 — Know the Fail Path

Escalate in order; document why each escalation was needed. Do not jump to 3 if 1 is available.
1. **Debugger** — step to the failure site (one breakpoint beats ten logs).
2. **Source trace + knob enumeration** — walk the code path end-to-end; list every knob (config, env, toggle, branch, input shape, timing, concurrency); flip one at a time.
3. **In-code instrumentation** — only if knobs cannot move the failure. Tag each probe with a unique prefix (e.g. `[DBG-a4f2]`) for clean removal later.

## STEP 1.3 — Falsify the Hypothesis

Generate **3–5 ranked hypotheses**, not one. Each must explain the symptom end-to-end — walk it through. Find the simplest proof AND disproof for each → **run the disproof first.** Survives = real; dies = five hours saved. No fix committed until a hypothesis survives disproof.

## STEP 1.4 — Breadcrumb Ledger

Session ledger: each entry = what changed, what happened, what it ruled in/out.
- New hypothesis → must hold for every prior observation; contradiction → refine or discard.
- Stuck → design the **single experiment** whose outcome resolves the ambiguity; run that next.

## HARD RULES

Mantra once per session, verbatim · steps 1→2→3→4 · no fix proposed until GATE 1 passes · no hypothesis testing until 1.2 narrows the path · no hypothesis committed until 1.3 disproof attempt · caught proposing a fix without repro → return to GATE 1 · **after applying any fix: rerun the GATE 1 repro and see it pass, plus the verify recipe (`references/verify.md`)** — green output is done; "the fix should work" is not.
