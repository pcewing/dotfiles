#!/usr/bin/env python

import os
import shutil

from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.common.python_files import PythonFiles
from dot.lib.common.util import sh


class LinterError(Exception):
    """Raised for user-facing setup problems (e.g. a required tool is missing)."""


class Linter:
    _tools: dict[str, str] = {}

    @staticmethod
    def lint(paths: list[str]) -> bool:
        files = PythonFiles.resolve(paths)
        if not files:
            Log.warn("no Python files found", {"paths": paths})
            return True

        ruff = Linter._tool("ruff")
        mypy = Linter._tool("mypy")
        ini = os.path.join(Dir.dot(), "mypy.ini")

        args = [Linter._display_path(f) for f in files]
        py_files = [f for f in args if f.endswith(".py")]
        script_files = [f for f in args if not f.endswith(".py")]

        checks: list[tuple[str, list[str], int]] = [
            ("ruff format", [ruff, "format", "--check", *args], len(args)),
            (
                "ruff check",
                [ruff, "check", "--output-format", "concise", *args],
                len(args),
            ),
        ]
        if py_files:
            checks.append(
                ("mypy", [mypy, "--config-file", ini, *py_files], len(py_files))
            )
        for script in script_files:
            # Each extensionless script is module __main__, so check them separately.
            checks.append((f"mypy {script}", [mypy, "--config-file", ini, script], 1))

        results: list[tuple[str, bool]] = []
        for name, cmd, count in checks:
            Log.info("running check", {"check": name, "files": count})
            results.append((name, sh(cmd, cwd=Dir.dot()) == 0))

        width = max(len(name) for name, _ in results)
        print("lint summary:")
        for name, ok in results:
            print(f"  {name.ljust(width)}  {'passed' if ok else 'FAILED'}")
        return all(ok for _, ok in results)

    @staticmethod
    def tidy(paths: list[str], dry_run: bool) -> None:
        files = PythonFiles.resolve(paths)
        if not files:
            Log.warn("no Python files found", {"paths": paths})
            return

        ruff = Linter._tool("ruff")
        args = [Linter._display_path(f) for f in files]
        steps = [
            (
                "fixing imports",
                [ruff, "check", "--fix", "--exit-zero", "--select", "I,F401", *args],
            ),
            ("formatting", [ruff, "format", *args]),
        ]
        for name, cmd in steps:
            Log.info(name, {"files": len(args)})
            if dry_run:
                Log.info("skipping due to --dry-run", {"command": " ".join(cmd)})
                continue
            sh(cmd, check=True, cwd=Dir.dot())

    @staticmethod
    def _display_path(path: str) -> str:
        rel = os.path.relpath(path, Dir.dot())
        if rel == ".." or rel.startswith(".." + os.sep):
            return path
        return rel

    @staticmethod
    def _tool(name: str) -> str:
        cached = Linter._tools.get(name)
        if cached is not None:
            return cached

        if os.name == "nt":
            venv_path = os.path.join(Dir.dot(), ".venv", "Scripts", name + ".exe")
        else:
            venv_path = os.path.join(Dir.dot(), ".venv", "bin", name)

        if os.path.isfile(venv_path) and os.access(venv_path, os.X_OK):
            path = venv_path
        else:
            found = shutil.which(name)
            if found is None:
                repo = Dir.dot()
                raise LinterError(
                    f"{name} not found; install the dev extras: "
                    f"{repo}/.venv/bin/pip install -e '{repo}[dev]'"
                )
            Log.warn(
                "using tool from PATH; results may differ from the dotfiles virtualenv",
                {"tool": name, "path": found},
            )
            path = found

        Linter._tools[name] = path
        return path
