#!/usr/bin/env bash
# sheerstatus — local self-test suite
# Verifies CLI routing, 9 locales, and JSON format.
#
# Rendering follows the CVER CLI signet (signet/packages/cli/SPEC.md), the same
# as the tool it tests. A harness ships with nothing, so it carries no seal —
# but it is a screen a person reads, and reading two languages in one sitting is
# the thing the signet exists to stop.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/sheerstatus"

# Counted, not asserted: this line used to end with a hard-coded "(10/10)" while
# the suite actually ran 13 checks. A total that can't be wrong is worth four
# lines of bookkeeping.
CHECKS=0
pass() { CHECKS=$((CHECKS + 1)); printf '   [ PASS ] %s\n' "$1"; }
fail() { printf '   [ FAIL ] %s\n' "$1"; exit 1; }

echo "▸ sheerstatus — local self-test"
echo ""

# Test 1: Executable existence
[ -x "$TARGET" ] || fail "sheerstatus script is not executable"
pass "Script executable check"

# Test 2: Version flag
VERSION_OUTPUT="$("$TARGET" --version)"
case "$VERSION_OUTPUT" in
  *"sheerstatus v"*) pass "--version flag check (${VERSION_OUTPUT})" ;;
  *) fail "--version returned unexpected output: ${VERSION_OUTPUT}" ;;
esac

# Test 3: Help flag
HELP_OUTPUT="$("$TARGET" --help)"
case "$HELP_OUTPUT" in
  *"Usage:"*) pass "--help flag check" ;;
  *) fail "--help output invalid" ;;
esac

# Test 4: JSON output validation
JSON_OUTPUT="$("$TARGET" --json)"
case "$JSON_OUTPUT" in
  *'"version":'*) : ;;
  *) fail "--json output invalid: ${JSON_OUTPUT}" ;;
esac
case "$JSON_OUTPUT" in
  *'"chip":'*) pass "--json output structure check" ;;
  *) fail "--json output invalid: ${JSON_OUTPUT}" ;;
esac

# Test 5: 9-locale sweep
LOCALES=("en-US" "ja-JP" "zh-TW" "zh-Hans" "ko-KR" "es-ES" "de-DE" "fr-FR" "pt-BR")

echo ""
echo "▸ Locale sweep"
for lang in "${LOCALES[@]}"; do
  out="$(SHEERSTATUS_LANG="$lang" "$TARGET")"
  case "$out" in
    *sheerstatus*) pass "$lang" ;;
    *) fail "Locale sweep failed for $lang" ;;
  esac
done

# Test 6: every localized t() key must name every locale
#
# The obvious version of this gate — "t <key> returns something in every
# locale" — cannot see a partial translation, because a missing branch falls
# through to *) and returns English, which is very much something. That is how
# this tool shipped a README promising 9 locales while its whole verdict and
# recommendation sections were 4: nothing ever failed, it just quietly spoke
# English.
#
# So the gate reads the SHAPE. A key whose body opens `case "$SS_LANG"` is
# claiming per-language text, so every locale must appear as a branch label;
# a key with no such case (a badge, a bare glyph) is deliberately universal and
# is left alone. The distinction is structural — no list of exceptions to keep.
#
# Both lists are extracted from the script itself, so adding a language or a key
# is enforced automatically, without editing this file.
echo ""
echo "▸ i18n"
LOCLIST="$(awk '/^ss_resolve_lang\(\) \{/,/^\}/' "$TARGET" \
  | grep -oE 'echo "[A-Za-z-]+"' | sed 's/echo //; s/"//g' | sort -u | tr '\n' ',' | sed 's/,$//')"
N_LOC="$(printf '%s' "$LOCLIST" | tr ',' '\n' | grep -c .)"

MISSING="$(awk -v LOCLIST="$LOCLIST" '
  BEGIN { NLOC = split(LOCLIST, LOC, ",") }
  /^t\(\) \{/            { inT = 1; next }
  inT && /^\}/           { if (key != "") emit(); inT = 0; next }
  !inT                   { next }
  /^    [a-z][a-z_0-9]*\)/ {
    if (key != "") emit()
    key = $0; sub(/\).*/, "", key); sub(/^ +/, "", key); body = ""
    next
  }
  { body = body "\n" $0 }
  function emit(   i, loc, gap) {
    if (index(body, "case \"$SS_LANG\"") == 0) { key = ""; body = ""; return }
    gap = ""
    for (i = 1; i <= NLOC; i++) {
      loc = LOC[i]
      # a label may stand alone (es-ES) or share a branch (zh-TW|zh-Hans)
      if (body !~ ("(^|[\n|(])[ \t]*" loc "[|)]")) gap = gap " " loc
    }
    if (gap != "") printf "%s:%s\n", key, gap
    key = ""; body = ""
  }
' "$TARGET")"

if [ -z "$MISSING" ]; then
  pass "every localized key names all $N_LOC locales"
else
  printf '%s\n' "$MISSING" | sed 's/^/     /'
  fail "a localized key is missing a locale (it would silently fall back to English)"
fi

# A test run changes nothing, so the closing badge is PASS, not DONE — the same
# question the tool's own report answers: did this change the disk?
echo ""
printf '[ PASS ] %s checks, none failed\n' "$CHECKS"
