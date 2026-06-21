#!/bin/sh
# Regression suite for hooks/verify-guard.sh — freezes the Stop hook's contract.
# Pure POSIX sh (zero dep beyond jq, which the hook already requires). Invokes the
# hook with bash to match its shebang. Fixtures are synthetic; never echoes real
# transcript content. See test/README.md for the case matrix.
#
# Exit 0 = all cases pass; exit 1 = any case failed.
set -u

ROOT="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/hooks/verify-guard.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

pass=0
fail=0

# Emit one assistant transcript line carrying text $1 (real Claude Code shape).
asst() { jq -nc --arg t "$1" \
  '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:$t}]}}'; }

# Run the hook with transcript_path $1 and stop_hook_active $2 (default false).
# Echoes "block" or "allow".
run_hook() {
  _tp="$1"; _sa="${2:-false}"
  _out="$(jq -nc --arg p "$_tp" --argjson s "$_sa" \
            '{transcript_path:$p, stop_hook_active:$s}' | bash "$HOOK" 2>/dev/null)"
  case "$_out" in
    *'"decision":"block"'* | *'"decision": "block"'*) echo block ;;
    *) echo allow ;;
  esac
}

# check NAME EXPECTED ACTUAL
check() {
  if [ "$2" = "$3" ]; then
    printf 'PASS  %s\n' "$1"; pass=$((pass + 1))
  else
    printf 'FAIL  %s (expected %s, got %s)\n' "$1" "$2" "$3"; fail=$((fail + 1))
  fi
}

# --- case 1: banner + claim + no VERIFIED -> block ---
asst '> #dbg | GATE 1 PASS | STEP 1.2
fixed the middleware, done' > "$TMP/c1.jsonl"
check "1 banner+claim+no-VERIFIED -> block" block "$(run_hook "$TMP/c1.jsonl")"

# --- case 2: banner + claim + VERIFIED present -> allow ---
asst '> #dbg | GATE 1 PASS | STEP 1.2
VERIFIED:
$ npm test
12 passed, 12 total
all done' > "$TMP/c2.jsonl"
check "2 banner+claim+VERIFIED -> allow" allow "$(run_hook "$TMP/c2.jsonl")"

# --- case 3: no banner + claim -> allow (self-scoping) ---
asst 'just refactored the parser, all done now' > "$TMP/c3.jsonl"
check "3 no-banner+claim -> allow (self-scoping)" allow "$(run_hook "$TMP/c3.jsonl")"

# --- case 4: banner + Thai claim + no VERIFIED -> block ---
asst '> #ft | GATE 2 PASS | STEP 2.4
งานเสร็จแล้ว' > "$TMP/c4.jsonl"
check "4 banner+TH-claim -> block" block "$(run_hook "$TMP/c4.jsonl")"

# --- case 5: banner + substring false-positives, no real claim -> allow ---
# "already / framework / workspace / abandoned" must NOT trigger the EN claim set.
asst '> #rf | GATE 3 PASS | STEP 3.1
I already moved the framework into the workspace and abandoned the legacy path' > "$TMP/c5.jsonl"
check "5 substring false-pos -> allow (regression guard)" allow "$(run_hook "$TMP/c5.jsonl")"

# --- case 6: fail-open ---
check "6a empty transcript_path -> allow (fail-open)" allow "$(run_hook "")"
check "6b unreadable transcript -> allow (fail-open)" allow "$(run_hook "$TMP/does-not-exist.jsonl")"

# --- case 7: stop_hook_active:true -> allow (loop guard) ---
asst '> #dbg | GATE 1 PASS
done' > "$TMP/c7.jsonl"
check "7 stop_hook_active -> allow (loop guard)" allow "$(run_hook "$TMP/c7.jsonl" true)"

# --- case 8: claim with 205 trailing non-assistant lines -> block (blind spot FIXED) ---
# Banner+claim is the FIRST line; 205 trailing user lines follow. The hook now prefilters
# to assistant lines BEFORE the head cap, so the lone assistant claim survives the window
# and is still caught. This pins the FIXED behavior (was a documented allow blind spot).
asst '> #dbg | GATE 1 PASS
done' > "$TMP/c8.jsonl"
i=0
while [ "$i" -lt 205 ]; do
  jq -nc '{type:"user",message:{role:"user",content:"noise"}}' >> "$TMP/c8.jsonl"
  i=$((i + 1))
done
check "8 claim + 205 trailing non-assistant lines -> block (blind spot fixed)" block "$(run_hook "$TMP/c8.jsonl")"

# --- case 9: malformed banner -> allow (pins scope regex) ---
asst '>#dbg without a space
done' > "$TMP/c9.jsonl"
check "9 malformed banner -> allow" allow "$(run_hook "$TMP/c9.jsonl")"

# --- case 10: banner + claim + a mid-sentence literal "VERIFIED:" -> block (anchoring) ---
# A bare "VERIFIED:" quoted mid-line (not at line start) must NOT satisfy the block check.
# The grep is anchored ^[[:space:]]*(NOT )?VERIFIED:, so this still blocks on the claim.
asst '> #dbg | GATE 1 PASS
I labelled it VERIFIED: in my notes and it works' > "$TMP/c10.jsonl"
check "10 mid-sentence VERIFIED: literal -> block (anchored)" block "$(run_hook "$TMP/c10.jsonl")"

# --- summary ---
printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
