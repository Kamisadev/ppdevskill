# `#rv` — Review

Stand outside the change. Ask whether it should exist at all, then verify it does what it claims.

## GATE 4 — Operating Stance

**Outsider** — read cold, forget who wrote it · **end-to-end, not diff-local** — the diff is the entry point, not the scope; follow the call graph · **no rubber stamps** — "LGTM" is not output; found nothing → state what you traced · **cite or it didn't happen** — every claim references a specific path/file:line.

## STEP 4.1 — Intent

State the goal in one sentence in your own words; cannot → artifact underspecified, say so and stop. Ask: **is there a simpler, smaller, or more elegant alternative?** (doing nothing, existing code, a smaller change with 90% of the value, a different layer) — name it with rationale BEFORE line-by-line review; usually the most valuable output. Wrong design decision → say it here, not buried in finding #7.

## STEP 4.2 — Trace

For each claimed behavior, trace end-to-end through real code, including unchanged code on both sides (**bugs hide at the seams**). For a plan/design doc: trace the proposed flow against the existing system — what does it assume that isn't true? Note every surprise (surprises are signal).

## STEP 4.3 — Verify

Does the traced path actually produce the behavior (walk A→B→C)? · What inputs/states break it? · What does it silently change (perf, error semantics, observability, caller contracts)? · Do the tests exercise the traced path, or pass while skipping it?

## STEP 4.4 — Security Dimension (if the change touches a trust boundary)

Change touches input / authz / token / file / query / shell / crypto / secret / network / dependency → Read `references/sec.md` and walk the OWASP Top 10 (2021) table for the categories it touches. Focus: is access scoped to the caller (A01/IDOR)? · is every query parameterized and output encoded (A03)? · are secrets/PII kept out of logs and responses (A02/A09)? · does a malicious input get rejected, not executed? Cite `file:line`. **A confirmed security finding is a blocker** — ranks above any style nit. No boundary touched → say so in one line.

## STEP 4.5 — Report

One tight section per finding, ordered **blocker → major → nit** (security findings rank as blocker). Each: **Finding** (one sentence + `file:line`) / **Why it matters** (consequence, not principle) / **Evidence** (the trace step that exposes it) / **Suggested change** (concrete, minimal). Close with a one-line verdict — **ship / fix-then-ship / rework / reject** — plus the single biggest reason.

## HARD RULES

No rubber stamps · cite or it didn't happen · claim ≠ verification ("the PR says X" ≠ "I traced X and confirmed") · one simpler-alternative pass mandatory unless the user says not to question scope · no padding with style nits when there is a structural problem · no flattery, no hedging.
