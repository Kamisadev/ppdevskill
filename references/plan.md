# `#plan` — Ultra Plan (Orchestrator)

The job is not writing code. It is turning a large, fuzzy, multi-step ask into an ordered set of small slices — each tagged with the mode that will build it, each independently testable and revertable — then handing slices off to `#dbg`/`#ft`/`#rf` one at a time. **This mode never edits code.** It decomposes, sequences, and hands off. Like `#bs`, it produces a plan and stops.

## WHEN IT APPLIES — the size gate (check first, refuse if too small)

`#plan` earns its cost only when the work is genuinely big:
- spans **>1 mode** (e.g. needs a refactor seam *then* a feature *then* a debug pass), **OR**
- breaks into **>3 slices**, **OR**
- has cross-slice **dependencies / sequencing risk** (slice B can't start until A lands).

Fails all three → **do not plan.** Route straight to the single mode that fits and say so in one line: *"งานนี้เล็กพอ ไม่ต้อง #plan — เข้า #ft ตรงๆ."* A plan for a one-slice task is over-engineering (Principle 6 + value gate).

## GATE 0 — Four preconditions (all required before producing a plan)

- [ ] **Outcome stated as an end state, not a task list** — "ผู้ใช้ export รายงานเป็น PDF ที่มีลายเซ็นได้" not "เพิ่มปุ่ม + เขียน endpoint." The outcome is the acceptance target the whole plan is judged against.
- [ ] **Size gate passed** — the work meets the >1-mode / >3-slice / dependency bar above. Otherwise refuse and route direct.
- [ ] **Constraints + unknowns surfaced** — deadlines, must-not-break contracts, tech locked in, and the open questions whose answers change the plan shape. An unknown that changes sequencing is a blocker → name it, do not guess (Principle 3).
- [ ] **Definition of done for the whole arc** — how we know the *outcome* (not each slice) is achieved. No DoD → outcome not ready, return to the user.

Cannot satisfy a checkbox → state which one, stop, wait. The approach itself undecided → **OFFER `#bs`** before planning (you can't sequence slices when the approach is unpicked).

## STEP P.1 — Decompose into slices

Break the arc into the smallest slices that each deliver a *testable* increment. Rules:
- A slice is **one mode's worth of work** (`#dbg` / `#ft` / `#rf`) — never a mix. A slice that is "refactor the seam *and* add the feature" is two slices (Principle 5).
- "Build the whole thing" is not a slice. If a slice can't be stated as one given/when/then, it's too big — split it.
- Order by **dependency, not by comfort.** Make-the-change-easy refactors come before the feature that needs the seam (`#ft` STEP 2.3).

## STEP P.2 — Tag, sequence, risk each slice

For every slice, fill the row fully:

| # | Slice (outcome) | Mode | Depends on | Risk / unknown | Rollback | Verify (recipe) |
|---|---|---|---|---|---|---|

- **Mode** — which of `#dbg`/`#ft`/`#rf` builds it (and so which gate it will face).
- **Depends on** — slice numbers that must land first. This defines the critical path.
- **Risk / unknown** — the one thing most likely to make this slice harder than it looks; blank means you haven't looked.
- **Rollback** — how to undo this slice alone if it goes wrong (feature flag, revert commit, drop column). A slice with no rollback story is a slice you can't safely ship.
- **Verify** — pointer to the `references/verify.md` recipe the receiving mode will run at its "done."

## STEP P.3 — Name the critical path + first slice

State the dependency chain that determines total time, and which slices can run in parallel. Then name **slice 1** — the one with no unmet dependency — and hand off: *"แผนพร้อม. slice 1 = [x], เข้า `#ft`. เริ่มเลยไหม?"* Stop. The user (or you, next turn) enters that mode; the slice faces that mode's gate **in full** — `#plan` grants no exemption.

## HARD RULES

`#plan` **never writes or edits code** — it plans and hands off (same contract as `#bs`) · GATE 0 + size gate before any plan · persist the slice table + outcome + DoD to `.ppdev/plan-ledger.md` and re-anchor from it, not memory (the arc outspans one context window — this is the whole point) · **ledger holds one arc only — overwrite on a new arc, mark slices `[x]` in place as they verify, edit the table in place on replan (never stack a second copy), clear the file when the outcome DoD is met** (full lifecycle: SKILL.md → MECHANICAL ENFORCEMENT → Ledger) · every slice is one mode, testable, revertable · order by dependency · a slice's mode gate is never pre-satisfied by the plan · replan when reality diverges (slice reveals a new dependency → stop, edit the ledger in place, re-sequence — don't push a stale plan) · the plan is done when every slice is verified by its own mode, not when the table is written.

## HANDOFF

`#plan` → slice 1 → its mode (`#dbg`/`#ft`/`#rf`) → VERIFIED → `#cp` (offer) → back to ledger → slice 2 ... → outcome DoD met → optional `#rv` over the whole arc → `#pm` if it was a fix arc. Approach undecided at GATE 0 → `#bs` first. A slice that turns out to need its own sub-plan is a smell the slice was too big — split it, don't nest `#plan`.
