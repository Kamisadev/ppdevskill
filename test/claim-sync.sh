#!/bin/sh
# Claim-word sync linter — fails when the claim-word set in SKILL.md self-check 8
# diverges from CLAIM_EN/CLAIM_TH in hooks/verify-guard.sh. The list is load-bearing
# and duplicated by design ("change one, change both"); this makes the sync mechanical.
# Pure POSIX sh, no jq. Exit 0 = in sync; exit 1 = drift (prints both directions).
set -u

# Byte-wise collation. Under a UTF-8 locale, `sort -u` collapses distinct Thai words as
# collation-equal (observed under LANG=af_ZA.UTF-8: เรียบร้อย silently dropped), which would
# make the linter blind to drift on that word. C locale makes sort/comm deterministic and exact.
export LC_ALL=C

ROOT="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/SKILL.md"
HOOK="$ROOT/hooks/verify-guard.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

# --- SKILL.md set: isolate the "claim-word ( ... , or equivalent)" region, pull backticked tokens ---
# Backtick (0x60) never appears inside UTF-8 multibyte sequences, so `[^`]+` safely captures Thai too.
# Dual anchor: only the enumeration line carries BOTH "claim-word (" and ", or equivalent)" — this
# excludes principle 12's "claim-word (list in self-check 8)" line, which would leak `VERIFIED:` tokens.
grep -F 'claim-word (' "$SKILL" | grep -F ', or equivalent)' \
  | sed -e 's/.*claim-word (//' -e 's/, or equivalent).*//' \
  | grep -oE '`[^`]+`' | sed 's/`//g' \
  | sort -u > "$TMP/skill.set"

# --- hook set: CLAIM_EN + CLAIM_TH values, split on | ---
{
  grep -E "^CLAIM_EN=" "$HOOK" | sed -E "s/^CLAIM_EN='//; s/'.*//"
  grep -E "^CLAIM_TH=" "$HOOK" | sed -E "s/^CLAIM_TH='//; s/'.*//"
} | tr '|' '\n' | sed '/^[[:space:]]*$/d' | sort -u > "$TMP/hook.set"

if [ ! -s "$TMP/skill.set" ]; then
  echo "claim-sync: FAIL — could not extract the claim-word list from SKILL.md (self-check 8 region)"; exit 1
fi
if [ ! -s "$TMP/hook.set" ]; then
  echo "claim-sync: FAIL — could not extract CLAIM_EN/CLAIM_TH from verify-guard.sh"; exit 1
fi

only_skill="$(comm -23 "$TMP/skill.set" "$TMP/hook.set")"
only_hook="$(comm -13 "$TMP/skill.set" "$TMP/hook.set")"

if [ -z "$only_skill" ] && [ -z "$only_hook" ]; then
  printf 'claim-sync: OK — %s claim-words in sync\n' "$(wc -l < "$TMP/skill.set" | tr -d ' ')"
  exit 0
fi

echo "claim-sync: DRIFT — SKILL.md self-check 8 and verify-guard.sh disagree:"
[ -n "$only_skill" ] && { echo "  in SKILL.md but NOT in the hook regex:"; printf '    %s\n' $only_skill; }
[ -n "$only_hook" ]  && { echo "  in the hook regex but NOT in SKILL.md:"; printf '    %s\n' $only_hook; }
echo "  -> they are load-bearing mirrors; update both (SKILL.md:self-check 8 and hooks/verify-guard.sh CLAIM_EN/CLAIM_TH)."
exit 1
