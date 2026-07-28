#!/usr/bin/env bash
#
# Public-surface golden check for the OtplessEventIO Swift module.
#
# WHY THIS EXISTS
# ---------------
# OtplessEventIO is not consumed by merchants directly — it ships *inside* the OTPLESS
# iOS SDK (OtplessBM) and the iOS intelligence SDK. Both reach it through CocoaPods with
# an OPTIMISTIC version constraint:
#
#     s.dependency 'OtplessEventIO', '~> 1.0'
#
# That is a RANGE. Any 1.x release is picked up by a `pod install` in a merchant app
# with no review step anywhere in between. A renamed or re-signed public symbol is
# therefore a merchant-visible break shipped by a version bump alone.
#
# WHAT IT CHECKS
# --------------
# It runs the compiler's own symbol-graph extractor over the built module and diffs a
# normalised, sorted rendering of every public symbol (kind, path, declaration) against
# a committed golden. Because it reads the compiled module rather than the source text,
# it also catches surface changes that come from protocol conformances and default
# arguments, not just from edited declarations.
#
# Usage:
#   scripts/check-public-surface.sh            # verify against the golden
#   scripts/check-public-surface.sh --update   # regenerate the golden (review the diff!)
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MODULE="OtplessEventIO"
GOLDEN_PATH="api/public-surface.txt"

UPDATE=0
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=1
fi

# The package supports iOS and macOS; the golden is extracted for the macOS host triple
# because that is what builds without a device/simulator SDK on any machine and in CI.
# The public surface here is platform-independent (no #if os(...) in Sources/).
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
TARGET_TRIPLE="arm64-apple-macosx13.0"

if [[ "$(uname -m)" != "arm64" ]]; then
  TARGET_TRIPLE="x86_64-apple-macosx13.0"
fi

echo "Building $MODULE ..." >&2
swift build --target "$MODULE" >&2

MODULES_DIR=".build/debug/Modules"
if [[ ! -f "$MODULES_DIR/$MODULE.swiftmodule" ]]; then
  echo "error: $MODULES_DIR/$MODULE.swiftmodule not found after build" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

xcrun --sdk macosx swift-symbolgraph-extract \
  -module-name "$MODULE" \
  -I "$MODULES_DIR" \
  -sdk "$SDK_PATH" \
  -target "$TARGET_TRIPLE" \
  -minimum-access-level public \
  -output-dir "$WORKDIR" >&2

SYMBOLS_JSON="$WORKDIR/$MODULE.symbols.json"
if [[ ! -f "$SYMBOLS_JSON" ]]; then
  echo "error: symbol graph not produced at $SYMBOLS_JSON" >&2
  exit 1
fi

ACTUAL_PATH="$WORKDIR/actual-surface.txt"

# Deterministic rendering: one sorted line per public symbol.
#   <accessLevel> <symbol-kind> <dotted path> :: <declaration>
# Nothing version- or path-dependent (no USRs, no file paths, no source locations) so
# the golden is stable across machines and toolchain patch releases.
python3 - "$SYMBOLS_JSON" > "$ACTUAL_PATH" <<'PY'
import json, sys

data = json.load(open(sys.argv[1]))
lines = set()
for sym in data.get("symbols", []):
    access = sym.get("accessLevel", "?")
    if access not in ("public", "open"):
        continue
    kind = sym["kind"]["identifier"]
    path = ".".join(sym.get("pathComponents", []))
    decl = "".join(f["spelling"] for f in sym.get("declarationFragments", []))
    decl = " ".join(decl.split())
    lines.add(f"{access} {kind} {path} :: {decl}")

if not lines:
    sys.exit("error: symbol graph contained no public symbols — refusing to write a golden")

for line in sorted(lines):
    print(line)
PY

if [[ ! -s "$ACTUAL_PATH" ]]; then
  echo "error: extracted surface is empty — refusing to compare" >&2
  exit 1
fi

if [[ "$UPDATE" -eq 1 ]]; then
  mkdir -p "$(dirname "$GOLDEN_PATH")"
  cp "$ACTUAL_PATH" "$GOLDEN_PATH"
  echo "Updated golden file: $GOLDEN_PATH"
  exit 0
fi

if [[ ! -f "$GOLDEN_PATH" ]]; then
  echo "error: golden file $GOLDEN_PATH does not exist. Run with --update to create it." >&2
  exit 1
fi

if diff -u "$GOLDEN_PATH" "$ACTUAL_PATH"; then
  echo "OK: public surface of $MODULE matches $GOLDEN_PATH"
  exit 0
fi

cat >&2 <<EOF

=====================================================================
PUBLIC SURFACE CHANGED — the diff above is what consumers would see.
=====================================================================
OtplessEventIO ships inside the OTPLESS iOS SDK (OtplessBM) and
OTPlessIntelligence, both of which depend on it as 'OtplessEventIO',
'~> 1.0' — an open range. A 1.x release carrying the diff above reaches
merchant builds on the next \`pod install\`, with no review in between.

If the change is intentional:
  1. Confirm no consumer breaks (grep the iOS SDK and the iOS
     intelligence SDK for the symbol).
  2. Note it in CHANGELOG.md so the consumer's bump protocol can
     classify the bump — and if it is BREAKING, it needs a major
     version, because '~> 1.0' will otherwise pick it up silently.
  3. Regenerate the golden: scripts/check-public-surface.sh --update
If it is not intentional, fix the source.
EOF
exit 1
