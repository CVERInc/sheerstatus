#!/usr/bin/env bash
# sheerstatus — local self-test suite
# Verifies CLI routing, 9 locales, and JSON format.
#
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/sheerstatus"

echo "============================================================"
echo "sheerstatus — Running Local Test Suite"
echo "============================================================"

# Test 1: Executable existence
if [ ! -x "$TARGET" ]; then
  echo "[FAIL] sheerstatus script is not executable."
  exit 1
fi
echo "[PASS] Script executable check"

# Test 2: Version flag
VERSION_OUTPUT="$("$TARGET" --version)"
if echo "$VERSION_OUTPUT" | grep -q "sheerstatus v"; then
  echo "[PASS] --version flag check (${VERSION_OUTPUT})"
else
  echo "[FAIL] --version flag returned unexpected output: ${VERSION_OUTPUT}"
  exit 1
fi

# Test 3: Help flag
HELP_OUTPUT="$("$TARGET" --help)"
if echo "$HELP_OUTPUT" | grep -q "Usage:"; then
  echo "[PASS] --help flag check"
else
  echo "[FAIL] --help flag output invalid"
  exit 1
fi

# Test 4: JSON output validation
JSON_OUTPUT="$("$TARGET" --json)"
if echo "$JSON_OUTPUT" | grep -q '"version":' && echo "$JSON_OUTPUT" | grep -q '"chip":'; then
  echo "[PASS] --json output structure check"
else
  echo "[FAIL] --json output invalid: ${JSON_OUTPUT}"
  exit 1
fi

# Test 5: 9-Locale sweep
LOCALES=("en-US" "ja-JP" "zh-TW" "zh-Hans" "ko-KR" "es-ES" "de-DE" "fr-FR" "pt-BR")

for lang in "${LOCALES[@]}"; do
  out="$(SHEERSTATUS_LANG="$lang" "$TARGET")"
  if echo "$out" | grep -q "Verdict"; then
    echo "[PASS] Locale sweep: ${lang}"
  else
    echo "[FAIL] Locale sweep failed for ${lang}"
    exit 1
  fi
done

echo "============================================================"
echo "All sheerstatus local self-tests PASSED successfully! (10/10)"
echo "============================================================"
