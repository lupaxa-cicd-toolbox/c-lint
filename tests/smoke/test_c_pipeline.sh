#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PIPELINE="${ROOT}/src/pipeline.sh"

grep -q -- '-x c-header' "${PIPELINE}"
grep -q -- '--error-exitcode=1' "${PIPELINE}"
grep -qF "FILE_NAME_SEARCH_PATTERN='\\.(c|h)\$'" "${PIPELINE}"
if grep -q 'EXCLUDE_FILES=node_modules' "${PIPELINE}"; then
    echo "FAIL: c-lint must not default-exclude node_modules" >&2
    exit 1
fi

if ! command -v gcc >/dev/null 2>&1 || ! command -v cppcheck >/dev/null 2>&1; then
    echo "FAIL: gcc and cppcheck must be on PATH for the behavioural smoke" >&2
    exit 1
fi

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "FAIL: shellcheck must be on PATH" >&2
    exit 1
fi
shellcheck -x "${PIPELINE}" "${BASH_SOURCE[0]}"

GOOD="$(mktemp -d)"
BAD="$(mktemp -d)"
BOUNDS="$(mktemp -d)"
trap 'rm -rf "${GOOD}" "${BAD}" "${BOUNDS}"' EXIT
cp "${ROOT}/tests/smoke/fixtures/ok.c" "${ROOT}/tests/smoke/fixtures/ok.h" "${GOOD}/"
cp "${ROOT}/tests/smoke/fixtures/bad.c" "${BAD}/"
cp "${ROOT}/tests/smoke/fixtures/bounds.c" "${BOUNDS}/"

SCAN_ROOT="${GOOD}" bash "${PIPELINE}"
if SCAN_ROOT="${BAD}" bash "${PIPELINE}"; then
    echo "FAIL: bad.c should fail the pipeline" >&2
    exit 1
fi

if SCAN_ROOT="${BOUNDS}" bash "${PIPELINE}"; then
    echo "FAIL: bounds.c should fail the pipeline (cppcheck)" >&2
    exit 1
fi

echo "PASS: test_c_pipeline.sh"
