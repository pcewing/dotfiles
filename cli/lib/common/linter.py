#!/usr/bin/env python

from lib.common.dir import Dir
from lib.common.log import Log
from lib.common.file_walker import FileWalker
from lib.common.util import sh


class Linter:
    @staticmethod
    def lint(files: list[str]) -> None:
        if len(files) == 0:
            files = Linter._get_python_files()

        for file in files:
            Linter._lint(file)

    @staticmethod
    def tidy(files: list[str], dry_run: bool) -> None:
        if len(files) == 0:
            files = Linter._get_python_files()

        for file in files:
            Linter._tidy(file, dry_run)

    @staticmethod
    def _lint(file: str) -> None:
        # TODO: Implement this
        # - Make sure file is tidy
        #     - Probably easiest to just make a copy of the file, run tidy on the
        #       copy, then compare against the original
        #     - If there are differences, fail
        # - Static type checking
        #     - `mypy --config-file "$DOTFILES/mypy.ini" ...`
        raise Exception("Not yet implemented")

    @staticmethod
    def _tidy(file: str, dry_run: bool) -> None:
        Linter._remove_unused_imports(file, dry_run)
        Linter._sort_imports(file, dry_run)
        Linter._format_file(file, dry_run)

    @staticmethod
    def _get_python_files() -> list[str]:
        python_file_patterns = [
            "^.*\.py$",
            "^fzf_cached_wsl$",
            "^textpack$",
        ]

        def is_python_file(file_name: str) -> bool:
            for pattern in python_file_patterns:
                if re.match(pattern, file_name) is not None:
                    return True
            return False

        python_files = []
        for file in FileWalker.enumerate(Dir.dot()).get_files():
            if is_python_file(file.get_name()):
                python_files.append(file.get_absolute_path())
        return python_files

    @staticmethod
    def _remove_unused_imports(file: str, dry_run: bool) -> None:
        Log.info("removing unused imports", [("file", file)])
        if not dry_run:
            sh(
                ["autoflake", "--in-place", "--remove-all-unused-imports", file],
                check=True,
            )

    @staticmethod
    def _sort_imports(file: str, dry_run: bool) -> None:
        Log.info("sorting imports", [("file", file)])
        if not dry_run:
            sh(["isort", file], check=True)

    @staticmethod
    def _format_file(file: str, dry_run: bool) -> None:
        Log.info("formatting file", [("file", file)])
        if not dry_run:
            sh(["black", file], check=True)
