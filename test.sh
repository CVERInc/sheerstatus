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

# Test 4: JSON output
#
# Asserting on `"version":` only proved the heredoc ran. What a consumer comes
# for is the VERDICT — the one thing this tool produces — and `--json` shipped
# without it until 0.8.0. Assert the product, and assert that readings are JSON
# numbers rather than the string "N/A" (a consumer doing arithmetic on "N/A"
# gets a silent zero).
JSON_OUTPUT="$("$TARGET" --json)"
for want in '"version":' '"chip":' '"verdict"' '"memory"' '"storage"' '"battery"'; do
  case "$JSON_OUTPUT" in
    *"$want"*) : ;;
    *) fail "--json is missing $want: ${JSON_OUTPUT}" ;;
  esac
done
case "$JSON_OUTPUT" in
  *'"N/A"'*) fail "--json emits the string \"N/A\" where a number or null belongs" ;;
esac
# every verdict must be one of the closed set
if printf '%s' "$JSON_OUTPUT" | tr -d ' \n' | grep -qE '"(memory|storage|battery)":"(pass|warn|crit|unknown)"'; then
  pass "--json carries the verdict, and readings are numbers or null"
else
  fail "--json verdict is not one of pass/warn/crit/unknown: ${JSON_OUTPUT}"
fi

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

# ── the npm channel: two files now claim the version, so something has to check
# that they agree. A "MUST match" nobody verifies is a wish, and the way it fails
# is quiet — npm ships 0.9.0 and `sheerstatus --version` says 0.8.0 to everyone
# who runs it. Also guards the packaging itself: what `files` promises to ship
# has to exist and be executable, or `npx sheerstatus` installs a broken shim.
echo ""
echo "▸ npm package"
PKG="${SCRIPT_DIR}/package.json"
if [ -f "$PKG" ]; then
  PKG_VER="$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PKG" | head -1)"
  SCRIPT_VER="$("$TARGET" --version | tr -dc '0-9.')"
  if [ -n "$PKG_VER" ] && [ "$PKG_VER" = "$SCRIPT_VER" ]; then
    pass "package.json version matches the script ($PKG_VER)"
  else
    fail "version drift: package.json says '$PKG_VER', the script says '$SCRIPT_VER'"
  fi
  # bin → the real file, and it must be executable: npm copies the mode bit
  BIN_REL="$(sed -n 's/.*"sheerstatus"[[:space:]]*:[[:space:]]*"\(\.\/[^"]*\)".*/\1/p' "$PKG" | head -1)"
  if [ -n "$BIN_REL" ] && [ -x "${SCRIPT_DIR}/${BIN_REL#./}" ]; then
    pass "package.json bin points at an executable file ($BIN_REL)"
  else
    fail "package.json bin does not point at an executable file (got '$BIN_REL')"
  fi
  # no install-time execution: the one npm hook that runs on someone else's
  # machine is the one this tool must never grow
  if grep -qE '"(postinstall|preinstall|install)"[[:space:]]*:' "$PKG"; then
    fail "package.json has an install-time script — this tool runs only when invoked"
  else
    pass "no install-time scripts (nothing runs until you run it)"
  fi
else
  fail "package.json is missing (the npm channel is part of the product now)"
fi

# A test run changes nothing, so the closing badge is PASS, not DONE — the same
# question the tool's own report answers: did this change the disk?
echo ""
printf '[ PASS ] %s checks, none failed\n' "$CHECKS"
