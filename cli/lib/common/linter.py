#!/usr/bin/env python

import hashlib
import os
import re
import shutil

from lib.common.dir import Dir
from lib.common.file_walker import FileWalker
from lib.common.log import Log
from lib.common.util import Util, sh


class Linter:
    @staticmethod
    def lint(files: list[str]) -> None:
        if len(files) == 0:
            files = Linter._get_python_files()

        Util.rmdir(Linter._tmp_dir())
        os.makedirs(Linter._tmp_dir())

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
        Linter._ensure_tidy(file)
        Linter._ensure_static_typing(file)

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

    @staticmethod
    def _ensure_tidy(file: str) -> None:
        dst = os.path.join(Linter._tmp_dir(), os.path.basename(file))
        shutil.copyfile(file, dst)
        Linter.tidy([dst], False)
        if Linter._file_md5(file) != Linter._file_md5(dst):
            raise Exception(f"File is not tidy: {file}")

    @staticmethod
    def _ensure_static_typing(file: str) -> None:
        mypy_cmd = ["mypy", "--config-file", os.path.join(Dir.dot(), "mypy.ini"), file]
        if sh(mypy_cmd) != 0:
            raise Exception(f"File does not have correct static type hints: {file}")

    @staticmethod
    def _tmp_dir() -> str:
        return os.path.join(Dir.tmp(), "linter")

    @staticmethod
    def _file_md5(file: str) -> str:
        md5 = hashlib.md5()
        with open(file, "rb") as f:
            md5.update(f.read())
        return md5.hexdigest()
