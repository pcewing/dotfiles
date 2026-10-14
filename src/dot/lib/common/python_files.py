import os
import subprocess

from dot.lib.common.dir import Dir


class PythonFilesError(Exception):
    """Raised for user-facing path problems (missing path, not a git work tree)."""


class PythonFiles:
    @staticmethod
    def resolve(paths: list[str]) -> list[str]:
        """Expand CLI path arguments into a sorted, de-duplicated list of
        absolute Python file paths."""
        if not paths:
            paths = [Dir.dot()]

        found: set[str] = set()
        for p in paths:
            a = os.path.abspath(p)
            if os.path.isdir(a):
                for f in PythonFiles._git_ls_files(a):
                    if PythonFiles.is_python_file(f):
                        found.add(f)
            elif os.path.isfile(a):
                found.add(a)
            else:
                raise PythonFilesError(f"path does not exist: {p}")
        return sorted(found)

    @staticmethod
    def is_python_file(path: str) -> bool:
        """True for *.py files and for extensionless files whose first line is
        a shebang that mentions python."""
        if path.endswith(".py"):
            return True
        if os.path.splitext(os.path.basename(path))[1] != "":
            return False
        try:
            with open(path, "rb") as f:
                first = f.readline(256)
        except OSError:
            return False
        return first.startswith(b"#!") and b"python" in first

    @staticmethod
    def _git_ls_files(directory: str) -> list[str]:
        """Absolute paths of the files git tracks under `directory`."""
        error = PythonFilesError(f"not inside a git work tree: {directory}")
        try:
            result = subprocess.run(
                ["git", "-C", directory, "ls-files", "-z"],
                capture_output=True,
            )
        except OSError as e:
            raise error from e
        if result.returncode != 0:
            raise error

        files: list[str] = []
        for rel in result.stdout.decode("utf-8", errors="surrogateescape").split("\0"):
            if not rel:
                continue
            path = os.path.join(directory, rel)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            files.append(path)
        return files
