# `#rf` — Refactor

Restructure without changing behavior. **The diff should be boring; the behavior identical.** Looks creative → it is a rewrite in disguise.

## GATE 3 — Three preconditions (before touching a line)

- [ ] **Safety net exists** — tests cover the code, OR characterization tests will be written first, OR the user acknowledges no net and provides a manual verification plan with specific scenarios.
- [ ] **Concrete motivation** — a named smell (STEP 3.2) or a near-term feature/fix this enables. "Make it cleaner" is not a motivation.
- [ ] **Behavior pinned** — one sentence stating what the code currently does that must keep doing. Cannot state it → read the code first.

A refactor without a safety net is a rewrite lying about itself.

## PARTNER CALL — Smell Interrogation (after GATE 3)

1. **Why does this smell exist?** — quick fix? missing abstraction? grew organically? Origin predicts whether it regrows.
2. **Does fixing it enable something specific?** — "just cleaner" is weak; "makes the upcoming payment refactor possible" is strong. Name the downstream benefit. "Just cleaner" → flag it, confirm worth the risk.

## STEPS

- **3.1 Pin:** tests exist → run them, see green before starting. No tests → write characterization tests capturing current behavior **including current bugs** (not the time to fix them; file separately).
- **3.2 Name the smell (one per session):** Duplication (3+ copies) · Long function/class · Misnamed thing · Tangled dependencies · Awkward seam · Dead code · Primitive obsession. Cannot name it = no target; stop.
- **3.3 Name the transform:** Rename · Extract · Inline · Move · Replace conditional with polymorphism · Introduce parameter object · Split phase. Cannot name it = you are rewriting; stop.
- **3.4 Verify:** one transform → **actually execute the test suite** → see green output → commit (message names the transform) → next. Tests red → **revert, do not debug.** Before declaring done, run the relevant verify recipe (`references/verify.md`) — e.g. a Next.js refactor still needs build + dev + route hit; refactors break SSR/RSC boundaries without failing a test.

## HARD RULES

Behavior preservation is the only job — bug spotted → write down, fix separately · persist the pinned behavior + transform sequence to `.ppdev/rf-ledger.md` (survives context compaction) · no "while I'm here" changes · boring diff · one commit per transform, bisectable, revertable · behavior changes mid-refactor → stop (net incomplete, or not a refactor) · resist the rewrite urge at 60% — note it, finish the sequence · tests must be RUN and observed green, never assumed.
