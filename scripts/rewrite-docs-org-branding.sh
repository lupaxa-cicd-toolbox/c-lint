#!/usr/bin/env bash
# Rewrite organisation branding in copied community docs/ Markdown files.
#
# Updates the centred logo block at the top of each docs/*.md file so the
# GitHub org href and brand-assets organisation logo path match the target
# organisation. For child orgs, also switches the footer image to
# footer-for-child-orgs.svg (href stays the-lupaxa-project).
# Do not add target="_blank": GitHub and PyPI strip it from Markdown.
#
# Usage:
#   ./scripts/rewrite-docs-org-branding.sh /path/to/target/repo ORG_LOGIN
#   ./scripts/rewrite-docs-org-branding.sh /path/to/target/docs ORG_LOGIN
#
# Brand folder rule: strip a leading "lupaxa-" from ORG_LOGIN
# (e.g. lupaxa-miscellaneous-toolbox → miscellaneous-toolbox).
# Orgs that already start with "the-lupaxa-" keep their login as the folder.
set -euo pipefail

TARGET="${1:-}"
ORG="${2:-}"
[[ -n "${TARGET}" && -n "${ORG}" ]] || {
  echo "Usage: $0 <target-repo-or-docs-dir> <github-org-login>" >&2
  exit 2
}

if [[ -d "${TARGET}/docs" ]]; then
  DOCS_DIR="${TARGET}/docs"
elif [[ -d "${TARGET}" ]]; then
  DOCS_DIR="${TARGET}"
else
  echo "ERROR: not a directory: ${TARGET}" >&2
  exit 1
fi

# shellcheck disable=SC2001
BRAND_SLUG="$(printf '%s' "${ORG}" | sed 's/^lupaxa-//')"

export DOCS_DIR ORG BRAND_SLUG
python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

docs_dir = Path(os.environ["DOCS_DIR"])
org = os.environ["ORG"]
brand_slug = os.environ["BRAND_SLUG"]
is_hub = org == "the-lupaxa-project"

org_href = f"https://github.com/{org}"
logo_src = (
    "https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/"
    f"master/logos/organisations/{brand_slug}/readme-logo.png"
)
# First <p align="center">…</p> block only (header logo). Drop any
# target/rel attributes; GitHub strips them.
header_re = re.compile(
    r'(<p align="center">\s*'
    r'<a href=")https://github\.com/[^"]+'
    r'"(?:\s[^>]*)?(>\s*'
    r'<img src=")https://raw\.githubusercontent\.com/the-lupaxa-project/'
    r'brand-assets/master/logos/organisations/[^/]+/readme-logo\.png(")',
    re.MULTILINE,
)

footer_img_re = re.compile(
    r'(https://raw\.githubusercontent\.com/the-lupaxa-project/brand-assets/'
    r'master/logos/components/)footer(?:-for-child-orgs)?\.svg'
)

changed = 0
for path in sorted(docs_dir.glob("*.md")):
    original = path.read_text(encoding="utf-8")
    text, n = header_re.subn(
        rf'\g<1>{org_href}"\g<2>{logo_src}\g<3>',
        original,
        count=1,
    )
    if not is_hub:
        text = footer_img_re.sub(r"\g<1>footer-for-child-orgs.svg", text)
    else:
        text = footer_img_re.sub(r"\g<1>footer.svg", text)
    # Drop target/rel on the footer image link. GitHub strips them.
    footer_link_re = re.compile(
        r'<a href="https://github.com/the-lupaxa-project"(?:\s[^>]*)?>'
        r'(?=\s*<img src="https://raw\.githubusercontent\.com/the-lupaxa-project/'
        r'brand-assets/master/logos/components/footer(?:-for-child-orgs)?\.svg")'
    )
    text = footer_link_re.sub(
        '<a href="https://github.com/the-lupaxa-project">',
        text,
    )
    if text != original:
        path.write_text(text, encoding="utf-8")
        changed += 1
        print(f"rewrote branding: {path}")

print(f"docs branding: {changed} file(s) updated for org={org} brand={brand_slug}")
if changed == 0:
    print("WARNING: no docs/*.md header blocks were rewritten", file=sys.stderr)
PY
