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

# Last assistant message that actually contains TEXT. A turn's final transcript lines
# can be tool_use blocks (no text); scan back (capped) to the most recent text-bearing
# assistant message. Content may be an array of blocks, a string, or under .message.text.
# Prefilter to assistant lines BEFORE the head cap so trailing non-assistant noise (a long
# run of user/tool lines) cannot evict the claim past the window -- closes the former
# head -200 blind spot (was test case 8). The cap now bounds assistant lines, not all lines.
TEXT=""
while IFS= read -r line; do
  case "$line" in *'"type":"assistant"'*) ;; *) continue ;; esac
  t="$(printf '%s' "$line" | jq -r '
    (.message.content // .message.text // .message) |
    if type=="array" then (map(select(.type=="text") | .text) | join("\n"))
    elif type=="string" then .
    else "" end' 2>/dev/null)"
  [ -n "$t" ] && { TEXT="$t"; break; }
done < <(reverse "$TRANSCRIPT" | grep '"type":"assistant"' | head -200)
[ -z "$TEXT" ] && allow

# Scope: only enforce on ppdevskill responses (identified by the mandatory banner).
printf '%s' "$TEXT" | grep -Eq '> #(dbg|ft|rf|rv|pm|cp|pp)\b' || allow

# Already has a verification block -> compliant, allow. (Covers VERIFIED: and NOT VERIFIED:.)
# Anchored at line-start (optional leading whitespace) so a bare literal "VERIFIED:" quoted
# mid-sentence -- e.g. while explaining these very rules -- does NOT satisfy the check.
printf '%s' "$TEXT" | grep -Eq '^[[:space:]]*(NOT )?VERIFIED:' && allow

# Claim-word present without a verification block -> violation (SKILL.md self-check 8 list).
# ASCII claims are bounded by a non-letter or a string edge -- portable across BSD/GNU/ugrep
# (\b is non-portable) -- so substrings like "abandoned"/"already"/"workspace"/"framework" do
# NOT false-trigger. Thai has no word breaks, so Thai claims match as-is.
# This list MUST stay in sync with SKILL.md self-check 8 (the model-side mirror).
CLAIM_EN='done|complete|completed|finished|ready|works|should work|looks good|LGTM'
CLAIM_TH='เสร็จ|เสร็จแล้ว|เรียบร้อย|พร้อมใช้|ใช้ได้แล้ว'
claimed=0
printf '%s' "$TEXT" | grep -Eiq "(^|[^a-zA-Z])(${CLAIM_EN})([^a-zA-Z]|\$)" && claimed=1
printf '%s' "$TEXT" | grep -Eq "$CLAIM_TH" && claimed=1
[ "$claimed" = 1 ] || allow

# Block: feed the reason back so the model fixes it this turn.
jq -nc '{
  decision: "block",
  reason: "ppdevskill: response makes a completion claim (done/เสร็จ/works/...) with NO VERIFIED: or NOT VERIFIED: block above it. SKILL.md principle 12 / self-check 8. Add the block (actual commands run + observed output), or replace the claim-word with a precise statement of what was actually accomplished. No third option."
}'
exit 0
