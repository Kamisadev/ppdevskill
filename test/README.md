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
| 8 | banner+claim + 205 trailing non-assistant lines | block — **blind spot fixed** (prefilter) |
| 9 | malformed banner (`>#dbg`, no space) | allow (pins scope regex) |
| 10 | banner+claim + mid-sentence literal `VERIFIED:` | block (anchored `^…VERIFIED:`) |

## Case 8 — blind spot now fixed (anchoring + prefilter)

The hook caps its scan at the last 200 reversed transcript lines. The former blind spot:
a claim made before 200+ trailing **non-assistant** lines was pushed past the window and
missed. The hook now **prefilters to assistant lines before the head cap**
(`reverse … | grep '"type":"assistant"' | head -200`), so trailing user/tool noise can no
longer evict the claim. Case 8 pins the fixed behavior (now `block`). Case 10 pins the
companion fix: the `VERIFIED:` check is anchored at line start
(`^[[:space:]]*(NOT )?VERIFIED:`), so a bare literal `VERIFIED:` quoted mid-sentence no
longer satisfies the block. A still-open limit: a claim before 200+ *assistant* text lines
in one turn remains out of window — far beyond any real single turn.

## What this slice deliberately does NOT do

- No edit to `verify-guard.sh` (this slice freezes behavior, never changes it).
- No claim-word sync linter (slice 2) and no CI wiring (slice 3).
- No test-framework dependency (no bats).
