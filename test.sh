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

# Test 3b: the router accepts -v and -h, so the help has to say so
# (as words of their own — "-v" is a substring of "--version")
for short in -v -h; do
  printf '%s\n' "$HELP_OUTPUT" | grep -qE -- "(^|[ ,|(])${short}([ ,|)]|\$)" \
    || fail "--help does not mention $short, which the router accepts"
done
pass "--help lists the -v and -h short flags"

# Test 3c: an unknown argument is an error, not a silent full report. A typo'd
# `--jsno` in a pipeline used to get human text and exit 0.
set +e
BOGUS_OUT="$("$TARGET" --jsno 2>/dev/null)"; BOGUS_RC=$?
set -e
if [ "$BOGUS_RC" -ne 0 ] && [ -z "$BOGUS_OUT" ]; then
  pass "unknown argument exits non-zero with nothing on stdout (rc $BOGUS_RC)"
else
  fail "unknown argument --jsno: rc $BOGUS_RC, stdout '${BOGUS_OUT%%$'\n'*}…'"
fi

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
# every verdict must be one of the closed set — EACH one. A single grep over the
# whole object passed as soon as any one key matched, so `"battery": "N/A"`
# beside a valid memory verdict sailed through.
JSON_FLAT="$(printf '%s' "$JSON_OUTPUT" | tr -d ' \n')"
json_verdict() { printf '%s' "$JSON_FLAT" | grep -oE "\"$1\":\"[^\"]*\"" | tail -1 | cut -d'"' -f4; }
for key in memory storage battery; do
  case "$(json_verdict "$key")" in
    pass|warn|crit|unknown) : ;;
    *) fail "--json verdict.$key is not one of pass/warn/crit/unknown: '$(json_verdict "$key")'" ;;
  esac
done
pass "--json carries the verdict, and readings are numbers or null"

# The report and --json must tell the same story. Each JSON verdict has exactly
# one report line with the same badge — and `unknown` has none, because a reading
# this machine can't take is omitted, not guessed at. This machine's own state is
# whatever it is; the stubbed cases further down pin the no-battery branch.
REPORT_EN="$(SHEERSTATUS_LANG=en-US "$TARGET")"
for pair in memory:RAM storage:Storage battery:Battery; do
  key="${pair%%:*}"; label="${pair#*:}"
  lines="$(printf '%s\n' "$REPORT_EN" | grep -E "^   \[ (PASS|WARN|CRIT) \] ${label}:" || true)"
  jv="$(json_verdict "$key")"
  if [ "$jv" = unknown ]; then
    [ -z "$lines" ] || fail "--json says $key is unknown, the report still verdicts it: $lines"
  else
    want="[ $(printf '%s' "$jv" | tr '[:lower:]' '[:upper:]') ]"
    case "$lines" in
      *"$want"*) : ;;
      *) fail "report and --json disagree on $key: json '$jv', report '${lines}'" ;;
    esac
  fi
done
pass "the report's verdict lines agree with --json (unknown prints no line)"

# Test 5: 9-locale sweep
LOCALES=("en-US" "ja-JP" "zh-TW" "zh-Hans" "ko-KR" "es-ES" "de-DE" "fr-FR" "pt-BR")

echo ""
echo "▸ Locale sweep"
for lang in "${LOCALES[@]}"; do
  out="$(SHEERSTATUS_LANG="$lang" "$TARGET")"
  # "the word sheerstatus appears" is true of any output at all; ask for a
  # verdict, and for no placeholder reading leaking into the text
  case "$out" in *sheerstatus*) : ;; *) fail "Locale sweep failed for $lang" ;; esac
  printf '%s\n' "$out" | grep -qE '^   \[ (PASS|WARN|CRIT) \] ' \
    || fail "$lang printed no verdict line"
  case "$out" in *N/A*) fail "$lang printed an N/A reading: $(printf '%s\n' "$out" | grep 'N/A')" ;; esac
  pass "$lang"
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

# ── the headroom verdict ─────────────────────────────────────────────────────
# Why these exist: sheerstatus printed [ PASS ] RAM: Ample (Swap 0 B) on a machine
# with 3.6 GB, no swap and no cushion — the PineNote, whose kernel is built with
# `CONFIG_SWAP is not set`. SwapTotal there is 0 for a structural reason, so the
# only signal the verdict read could never move. A gauge welded to green.
echo ""
echo "▸ memory verdict"
# shellcheck source=/dev/null
SHEERSTATUS_LIB=1 . "$TARGET"

vm_case() {   # $1 label · $2 expected · $3… args to the function under test
  local label="$1" want="$2" got; shift 2
  got="$("$@")"
  if [ "$got" = "$want" ]; then pass "$label"; else fail "$label — got '$got', want '$want'"; fi
}

vm_case "headroom 83% → pass"  pass    verdict_memory_avail 83
vm_case "headroom 25% → pass"  pass    verdict_memory_avail 25
vm_case "headroom 24% → warn"  warn    verdict_memory_avail 24
vm_case "headroom 10% → warn"  warn    verdict_memory_avail 10
vm_case "headroom 9%  → crit"  crit    verdict_memory_avail 9
vm_case "no such signal (macOS) → unknown" unknown verdict_memory_avail ""

# THE regression: swap says nothing (it cannot), headroom says the machine is
# nearly out. Before this existed the answer was 'pass'.
vm_case "swap 0 + headroom 5% → crit (the welded-gauge case)" crit \
        verdict_memory_both 0 3724 5
# and the reverse road: headroom fine, swap already being paid for
vm_case "swap 7700 MB + headroom 60% → crit" crit verdict_memory_both 7700 16384 60
# neither instrument alarmed
vm_case "swap 0 + headroom 80% → pass" pass verdict_memory_both 0 3724 80
# a machine with no MemAvailable at all must fall back to the swap reading only
vm_case "no headroom signal + swap 0 → pass" pass verdict_memory_both 0 16384 ""

# A tier that can be reached is worth more than a tier that is merely defined:
# the three above are the three the PineNote can actually pass through.

# (specs) the mount label exists to stop one partition being reported as the
# machine's storage — but only where there is something to disambiguate. With /
# and $HOME on the same device (every Mac, and most Linux boxes) it must stay
# silent, or every single-volume machine grows a suffix that says nothing.
#
# df is stubbed so both branches are reached on any runner: with the real df,
# HOME=/ makes the two lookups identical by construction and only the early
# return is ever exercised.
fake_df() {   # $1 = device for /  $2 = device for /home
  eval "df() {
    local last=\"\${!#}\"
    echo 'Filesystem 1024-blocks Used Available Capacity Mounted on'
    case \"\$last\" in
      /home*) echo '$2 100 50 50 50% /home' ;;
      *)      echo '$1 100 50 50 50% /' ;;
    esac
  }"
}
if [ "$(uname)" = "Darwin" ]; then
  # the label is Linux-only by design (a Mac's data volume is the whole story)
  [ -z "$(get_mount_label /)" ] || fail "mount label spoke up on macOS"
  pass "mount label is silent on macOS"
else
  got="$(fake_df /dev/sda1 /dev/sda1; HOME=/home/u get_mount_label /)"
  if [ -z "$got" ]; then
    pass "mount label is silent when / and \$HOME are the same filesystem"
  else
    fail "mount label spoke up on a single-filesystem machine: '$got'"
  fi
  got="$(fake_df /dev/sda1 /dev/sda2; HOME=/home/u get_mount_label /)"
  if [ "$got" = " (/)" ]; then
    pass "mount label names the mount when / and \$HOME are different filesystems"
  else
    fail "mount label with / and \$HOME on different devices — got '$got', want ' (/)'"
  fi
fi

# ── the battery verdict ─────────────────────────────────────────────────────
# A machine with no battery printed `[ CRIT ] Battery: Health severely degraded
# (N/A%).` — in all nine languages, on every CI runner (they are VMs), while
# --json said "unknown" and the recommendation said "excellent condition". The
# getters are stubbed so both roads are reached whatever this machine has.
echo ""
echo "▸ battery verdict"
# shellcheck disable=SC2317,SC2034  # the stub and SS_LANG are read by run_audit
audit_with_battery() {   # $1 = what get_battery_pct reports · $2 = locale
  ( STUB_BAT="$1"; SS_LANG="$2"; get_battery_pct() { echo "$STUB_BAT"; }; run_audit )
}
badge_lines() { printf '%s\n' "$1" | grep -cE '^   \[ (PASS|WARN|CRIT) \] ' || true; }
for lang in "${LOCALES[@]}"; do
  out="$(audit_with_battery N/A "$lang")"
  n="$(badge_lines "$out")"
  case "$out" in *N/A*) fail "$lang: no battery, but the report prints N/A: $(printf '%s\n' "$out" | grep 'N/A')" ;; esac
  [ "$n" -eq 2 ] || fail "$lang: no battery should leave 2 verdict lines (RAM, storage), got $n"
done
pass "no battery → no battery verdict line, in all ${#LOCALES[@]} locales"

out="$(audit_with_battery 75% en-US)"
printf '%s\n' "$out" | grep -qE '^   \[ WARN \] Battery: .*75%' \
  || fail "battery 75% should print a WARN battery line: $out"
case "$out" in *"$(SS_LANG=en-US t rec_battery)"*) : ;; *) fail "battery 75% should recommend a battery service" ;; esac
pass "battery 75% → WARN line, and the recommendation names the battery"

out="$(audit_with_battery 92% en-US)"
printf '%s\n' "$out" | grep -qE '^   \[ PASS \] Battery: .*92%' \
  || fail "battery 92% should print a PASS battery line: $out"
pass "battery 92% → PASS line"

# A test run changes nothing, so the closing badge is PASS, not DONE — the same
# question the tool's own report answers: did this change the disk?
echo ""
printf '[ PASS ] %s checks, none failed\n' "$CHECKS"
