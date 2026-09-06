#!/usr/bin/env bash
# Re-create vendor/daisyui at the pinned SHA and build it so class.json files exist.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHA="$(cat "$ROOT/fixtures/DAISYUI_SHA")"
if [ ! -d "$ROOT/vendor/daisyui/.git" ]; then
  git clone https://github.com/saadeghi/daisyui "$ROOT/vendor/daisyui"
fi
cd "$ROOT/vendor/daisyui"
git fetch --depth 1 origin "$SHA" || git fetch origin
git checkout --quiet "$SHA"
bun install
cd packages/daisyui && bun run build
