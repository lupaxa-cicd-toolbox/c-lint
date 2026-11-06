<p align="center">
  <a href="https://github.com/lupaxa-cicd-toolbox">
    <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/organisations/cicd-toolbox/readme-logo.png" alt="CICD Toolbox" />
  </a>
</p>

<h1 align="center">C Lint</h1>

This repository ships a portable pipeline script for C sources and headers.
It syntax-checks each `*.c` file with `gcc -fsyntax-only`, and each `*.h`
file with `gcc -fsyntax-only -x c-header`. It then runs `cppcheck` with
`--error-exitcode=1` on every matched file under the scan root.

Set `SCAN_ROOT` to point at the tree you want scanned (defaults to the current directory).

## Quick Start

From the repository root:

```bash
bash src/pipeline.sh
```

Or limit the scan to a single directory:

```bash
SCAN_ROOT=./path/to/sources bash src/pipeline.sh
```

<a href="https://github.com/the-lupaxa-project">
    <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/components/footer-for-child-orgs.svg" alt="The Lupaxa Project Footer" width="100%" />
</a>
