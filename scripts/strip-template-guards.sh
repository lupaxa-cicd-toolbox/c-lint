#!/usr/bin/env bash
# Strip lupaxa-template-guard job conditions from workflow YAML copied into a real repo.
#
# Usage:
#   ./scripts/strip-template-guards.sh /path/to/target/repo
#   ./scripts/strip-template-guards.sh /path/to/target/.github/workflows
set -euo pipefail

TARGET="${1:-}"
[[ -n "${TARGET}" ]] || { echo "Usage: $0 <target-repo-or-workflows-dir>" >&2; exit 2; }

if [[ -d "${TARGET}/.github/workflows" ]]; then
  WF_DIR="${TARGET}/.github/workflows"
elif [[ -d "${TARGET}" ]]; then
  WF_DIR="${TARGET}"
else
  echo "ERROR: not a directory: ${TARGET}" >&2
  exit 1
fi

python3 - <<'PY' "${WF_DIR}"
import re
import sys
from pathlib import Path

wf_dir = Path(sys.argv[1])
changed = 0
for path in sorted(wf_dir.glob("*.yml")):
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    out = []
    for line in lines:
        if "lupaxa-template-guard" not in line:
            out.append(line)
            continue
        # Status/summary jobs: keep always()
        if "always()" in line:
            indent = re.match(r"^(\s*)", line).group(1)
            out.append(f"{indent}if: always()\n")
        else:
            # Drop the guard entirely (primary jobs)
            continue
    new = "".join(out)
    if new != original:
        path.write_text(new, encoding="utf-8")
        changed += 1
        print(f"stripped: {path}")
print(f"Updated {changed} workflow file(s) under {wf_dir}")
PY
