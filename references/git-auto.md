# `#cp` — Commit & Push

An action, not a mode: it does not replace the active mode's gates — it is the commit step *after* work is verified. The commit message describes the change and **nothing else**.

## GATE — before committing

- [ ] **Inspected the real diff** — run `git status` + `git diff` (and `git diff --staged`). The message is derived from what the diff actually changed, never from memory or assumption.
- [ ] **Something to commit** — nothing staged/changed → say so, stop. Do not create an empty commit.
- [ ] **One logical change** — diff mixes unrelated work (behavior change + refactor, two features) → flag it, propose splitting into separate commits. Behavior change and refactor never share a commit (SKILL.md rule 5).
- [ ] **No secrets / junk** — scan the diff for keys, tokens, `.env`, credentials, large build artifacts, debug probes (`[DBG-...]`). Found → stop, do not commit (ties to `references/sec.md`, A02). Never `git add -A` blindly.
- [ ] **Stage only files in this change's scope** — `git add <path>` per file the logical change actually touched; never `git add -A` / `git add .` (they sweep in unrelated dirty files, scratch output, local config, editor cruft). Other files dirty in the tree → leave them untouched; a commit pulls in only what *this* change produced. This is the commit-side of surgical work (SKILL.md Principle 13): less junk in history, cleaner reverts, an honest one-purpose diff.

## COMMIT MESSAGE — only what was done

- **Subject** — imperative, concise (~50 chars), states what the change does: `fix token expiry off-by-one in auth middleware`. Match the repo's existing convention (read `git log --oneline -10`; if it uses Conventional Commits, follow it).
- **Body** — only when the *why* is not obvious from the subject. Still only about this change: what changed and why. No story, no filler.
- **NOTHING ELSE.** No AI attribution, no `Co-Authored-By`, no `Generated with`, no tool/model credit, no emoji, no banners, no ticket boilerplate the user didn't ask for, no off-topic text. The message is about the code change, full stop.
- Wrong / vague message ("update", "fix stuff", "changes") = not acceptable; describe the actual change.

## PUSH — only when the user wants it

- `#cp` alone = commit only. Push only when the user asks ("commit push" / "push" / "#cp push") or confirms.
- Pushing to a shared or default branch (`main`/`master`) is high-stakes → confirm first, or branch first per the user's workflow. A feature branch → push freely once asked.
- Never force-push (`--force`) without explicit instruction; prefer `--force-with-lease` if a force is genuinely required and approved.

## VERIFY

The commit/push is an action with observable output — show it, do not claim it:
- After commit: `git log -1 --stat` → paste subject + files changed.
- After push: paste the push output (branch, remote, commit range).
- Report in a `VERIFIED:` block (SKILL.md). Could not push (no remote, auth, network) → `NOT VERIFIED:` + the exact command the user must run.

## HARD RULES

Message describes only the change — no AI attribution, no off-topic text, ever · derive the message from the real diff, not memory · one logical change per commit · never commit secrets or `git add -A` blind · push only when asked · no force-push without explicit approval · show `git log -1` / push output, never claim "committed/pushed" without it.
