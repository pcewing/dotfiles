#!/usr/bin/env bash

set -euo pipefail

# Run from the repository root so stylua finds .stylua.toml and the paths below
# resolve, wherever the script is invoked from.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

status=0

# Check the formatting of every tracked Lua file. stylua is installed on Linux
# by `dot provision stylua`; on Windows, put stylua.exe on PATH. To fix the
# reported files, run `make fmt-lua` or `stylua <files>`.
git ls-files -z '*.lua' | xargs -0 stylua --check || status=1

# Lint the Python code (ruff format, ruff check, mypy) with the repo's dot CLI.
if [[ -x .venv/bin/dot ]]; then
    dot_bin=.venv/bin/dot
elif [[ -x .venv/Scripts/dot.exe ]]; then
    dot_bin=.venv/Scripts/dot.exe
else
    echo "error: dot binary not found in .venv; run ./bootstrap.sh" >&2
    exit 1
fi
"${dot_bin}" lint || status=1

exit "${status}"
