#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
mkdir -p "$BUILD"

# validator — no extra deps
echo "Building validator..."
cd "$ROOT/src/validator"
zip -q "$BUILD/validator.zip" handler.py
cd "$ROOT/src/common"
zip -q -u "$BUILD/validator.zip" tiers.json

# processor — needs psycopg2-binary
echo "Building processor..."
TMPDIR=$(mktemp -d)
uv pip install -q -r "$ROOT/src/processor/requirements.txt" -t "$TMPDIR"
cp "$ROOT/src/processor/handler.py" "$TMPDIR/"
mkdir -p "$TMPDIR/common"
cp "$ROOT/src/common/tiers.json" "$TMPDIR/common/"
cd "$TMPDIR"
zip -qr "$BUILD/processor.zip" .
rm -rf "$TMPDIR"

echo "Done. Zips in $BUILD/"
