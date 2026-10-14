#!/usr/bin/env bash

set -e

# Run from the repository root so stylua finds .stylua.toml and the paths below
# resolve, wherever the script is invoked from.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# Check the formatting of every tracked Lua file. stylua is installed on Linux
# by `dot provision stylua`; on Windows, put stylua.exe on PATH. To fix the
# reported files, run `make fmt-lua` or `stylua <files>`.
git ls-files -z '*.lua' | xargs -0 stylua --check
