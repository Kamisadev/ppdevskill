# test/ — regression suite for `hooks/verify-guard.sh`

Freezes the Stop hook's contract so a future edit cannot silently (a) stop blocking
(enforcement dies) or (b) break fail-open (bricks sessions).

```sh
sh test/run.sh        # all cases pass -> exit 0; any fail -> exit 1
```

Pure POSIX sh runner; depends only on `jq` (which the hook already requires) and `bash`
(to run the hook, matching its shebang). Fixtures are **synthetic** — the suite never
echoes real transcript content (the hook is designed to never log secrets; the suite upholds that).
`fixtures/golden.jsonl` is a real-shape Claude Code assistant line (thinking + text blocks)
kept for inspection; the runner builds the per-case fixtures itself.

## Case matrix

| # | Given | Then |
|---|-------|------|
| 1 | banner + claim `done` + no VERIFIED | block |
| 2 | banner + claim + `VERIFIED:` present | allow |
| 3 | no banner + claim | allow (self-scoping) |
| 4 | banner + Thai `เสร็จแล้ว` + no VERIFIED | block |
| 5 | banner + substrings `already/framework/workspace/abandoned`, no real claim | allow (regression guard) |
| 6 | empty / unreadable transcript path | allow (fail-open) |
| 7 | `stop_hook_active:true` | allow (loop guard) |
| 8 | banner+claim pushed past the `head -200` window | allow — **documented blind spot** |
| 9 | malformed banner (`>#dbg`, no space) | allow (pins scope regex) |

## Case 8 is a documented blind spot, not an endorsement

The hook scans only the last 200 reversed transcript lines for the most recent
text-bearing assistant message. A claim made before 200+ trailing non-text lines is
missed. Case 8 pins this **current** behavior so a refactor cannot change it unnoticed —
it does NOT assert the behavior is correct. Fixing the window is a separate change
(filed against the v1.4.0 arc, not this slice).

## What this slice deliberately does NOT do

- No edit to `verify-guard.sh` (this slice freezes behavior, never changes it).
- No claim-word sync linter (slice 2) and no CI wiring (slice 3).
- No test-framework dependency (no bats).
