#!/usr/bin/env bash
# tools/ci.sh — run the full CI pipeline in the exact order fixed by
# CLAUDE.md / SPEC.md "Constraints":
#
#   gen-schema diff -> elm make -> package-docs -> elm-review -> elm-test
#   -> render-audit -> should-not-compile -> gen-cally-css -> demo build
#   -> css-coverage -> Playwright
#
# render-audit is the static half of RenderPurityTest and so runs with it,
# right after elm-test.
#
# package-docs is the publish gate: `elm publish` builds the documentation and
# refuses a package whose exposed modules are missing a module comment or an
# @docs entry, and it refuses unformatted source. It sits with elm-make
# because it is the same compiler pass over the same files.
#
# Any failure stops the pipeline (set -e). bun/bunx only, never npm/npx.
#
# Usage:
#   bash tools/ci.sh                 # run every step, in order
#   bash tools/ci.sh --from elm-test # skip everything before elm-test
#   bash tools/ci.sh --list          # print step names and exit
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- step registry --------------------------------------------------------
# Order here IS the CI order. Do not reorder without updating the comment
# above and CLAUDE.md.
STEP_NAMES=(
  gen-schema
  elm-make
  package-docs
  elm-review
  elm-test
  render-audit
  should-not-compile
  gen-cally-css
  demo-build
  css-coverage
  playwright
)

step_gen-schema() {
  bun tools/gen-schema.js
}

step_elm-make() {
  elm make src/Daisy/Render.elm --output=/dev/null
}

step_package-docs() {
  # Everything `elm publish` checks before it will accept a version, minus the
  # git tag: the docs build (every exposed module documented) and formatting.
  local docs
  docs="$(mktemp -t elm-daisyui-docs-XXXXXX.json)"
  elm make --docs="$docs"
  rm -f "$docs"
  elm-format --validate src
}

step_elm-review() {
  # Rule tests first (positive/negative fixtures for the three custom
  # rules), then the lint itself against src/ and demo/src.
  (cd review && elm-test)
  elm-review
}

step_elm-test() {
  elm-test
}

step_render-audit() {
  bun tools/render-class-audit.js
}

step_should-not-compile() {
  bun tools/should-not-compile/run.js
}

step_gen-cally-css() {
  # demo/cally-base.css + demo/cally-daisy.css, the two stylesheets
  # `Leaf.Calendar` needs. Committed, but regenerated here so a drift from
  # vendor/daisyui or from the elm-cally version shows up as a diff.
  bun tools/gen-cally-css.js
}

step_demo-build() {
  (cd demo && bun install && bun run build)
}

step_css-coverage() {
  bun tools/css-coverage.js
}

step_playwright() {
  (cd e2e && bunx playwright test)
}

# --- banner ----------------------------------------------------------------
banner() {
  local n="$1" total="$2" name="$3"
  echo
  echo "======================================================================"
  printf '  [%d/%d] %s\n' "$n" "$total" "$name"
  echo "======================================================================"
}

# --- arg parsing -------------------------------------------------------------
FROM_STEP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from)
      FROM_STEP="${2:-}"
      if [ -z "$FROM_STEP" ]; then
        echo "error: --from requires a step name" >&2
        exit 2
      fi
      shift 2
      ;;
    --from=*)
      FROM_STEP="${1#--from=}"
      shift
      ;;
    --list)
      printf '%s\n' "${STEP_NAMES[@]}"
      exit 0
      ;;
    -h|--help)
      echo "Usage: bash tools/ci.sh [--from <step>] [--list]"
      echo "Steps: ${STEP_NAMES[*]}"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      echo "Usage: bash tools/ci.sh [--from <step>] [--list]" >&2
      exit 2
      ;;
  esac
done

START_INDEX=0
if [ -n "$FROM_STEP" ]; then
  FOUND=0
  for i in "${!STEP_NAMES[@]}"; do
    if [ "${STEP_NAMES[$i]}" = "$FROM_STEP" ]; then
      START_INDEX=$i
      FOUND=1
      break
    fi
  done
  if [ "$FOUND" -ne 1 ]; then
    echo "error: unknown step '$FROM_STEP'. Valid steps: ${STEP_NAMES[*]}" >&2
    exit 2
  fi
fi

TOTAL=${#STEP_NAMES[@]}
for i in "${!STEP_NAMES[@]}"; do
  if [ "$i" -lt "$START_INDEX" ]; then
    continue
  fi
  name="${STEP_NAMES[$i]}"
  banner "$((i + 1))" "$TOTAL" "$name"
  "step_${name}"
done

echo
echo "======================================================================"
echo "  CI: all steps passed"
echo "======================================================================"
