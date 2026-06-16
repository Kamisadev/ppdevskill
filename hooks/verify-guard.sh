#!/bin/bash
# ppdevskill — VERIFIED-block Stop hook (mechanical enforcement of SKILL.md self-check 8 / principle 12)
#
# Blocks the turn from ending when a ppdevskill response makes a completion claim
# without a VERIFIED:/NOT VERIFIED: block. Self-scoping: fires ONLY on responses that
# carry a ppdevskill banner (`> #dbg|#ft|#rf|#rv|#pm|#cp|#pp`). Other workflows untouched.
#
# SAFETY: fail-open. Any error, missing tool, or unreadable transcript -> exit 0 (allow).
# A discipline hook must never brick a session. Never logs transcript content (may hold secrets).

# --- fail-open guard: never let an unexpected error block the user ---
allow() { exit 0; }
trap 'allow' ERR

INPUT="$(cat)"

# jq is required to parse the hook input + transcript; absent -> fail open
command -v jq >/dev/null 2>&1 || allow

# Reverse a file line-wise. tac is GNU-only (absent on macOS); fall back to tail -r (BSD).
reverse() { tac "$1" 2>/dev/null || tail -r "$1" 2>/dev/null; }

# Loop guard: if this Stop hook already re-invoked the model (block in progress),
# do not block again -> prevents infinite block loops.
STOP_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)"
[ "$STOP_ACTIVE" = "true" ] && allow

TRANSCRIPT="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
[ -z "$TRANSCRIPT" ] && allow
[ -r "$TRANSCRIPT" ] || allow

# Last assistant message text. Flexible: content may be an array of blocks, a string,
# or live under .message.text. Extract text blocks and join. (transcript schema not pinned.)
LAST_OBJ="$(reverse "$TRANSCRIPT" | grep -m1 '"type":"assistant"')"
[ -z "$LAST_OBJ" ] && allow

TEXT="$(printf '%s' "$LAST_OBJ" | jq -r '
  (.message.content // .message.text // .message) |
  if type=="array" then (map(select(.type=="text") | .text) | join("\n"))
  elif type=="string" then .
  else tostring end
' 2>/dev/null)"
[ -z "$TEXT" ] && allow

# Scope: only enforce on ppdevskill responses (identified by the mandatory banner).
printf '%s' "$TEXT" | grep -Eq '> #(dbg|ft|rf|rv|pm|cp|pp)\b' || allow

# Already has a verification block -> compliant, allow. (Covers VERIFIED: and NOT VERIFIED:.)
printf '%s' "$TEXT" | grep -q 'VERIFIED:' && allow

# Claim-word present without a verification block -> violation (SKILL.md self-check 8 list).
CLAIM='done|complete|completed|finished|ready|works|should work|looks good|LGTM|เสร็จ|เสร็จแล้ว|เรียบร้อย|พร้อมใช้|ใช้ได้แล้ว'
printf '%s' "$TEXT" | grep -Eiq "$CLAIM" || allow

# Block: feed the reason back so the model fixes it this turn.
jq -nc '{
  decision: "block",
  reason: "ppdevskill: response makes a completion claim (done/เสร็จ/works/...) with NO VERIFIED: or NOT VERIFIED: block above it. SKILL.md principle 12 / self-check 8. Add the block (actual commands run + observed output), or replace the claim-word with a precise statement of what was actually accomplished. No third option."
}'
exit 0
