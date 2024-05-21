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
    class Error:
        def __init__(self, file, msg):
            self.file = file
            self.msg = msg

        @staticmethod
        def untidy(file):
            return Linter.Error(file, "file is not tidy")

        @staticmethod
        def incorrect_type_hints(file):
            return Linter.Error(file, "incorrect static type hints")

        def __str__(self) -> str:
            return f"{self.file}: {self.msg}"

    @staticmethod
    def lint(files: list[str]) -> None:
        if len(files) == 0:
            files = Linter._get_python_files()

        Util.rmdir(Linter._tmp_dir())
        os.makedirs(Linter._tmp_dir())

        errors = []
        for file in files:
            errors += Linter._lint(file)

        if len(errors) == 0:
            return

        for error in errors:
            print(error)

        raise Exception("Linter errors encountered")

    @staticmethod
    def tidy(files: list[str], dry_run: bool) -> None:
        if len(files) == 0:
            files = Linter._get_python_files()

        for file in files:
            Linter._tidy(file, dry_run)

    @staticmethod
    def _lint(file: str) -> list["Linter.Error"]:
        errors = []
        if not Linter._ensure_tidy(file):
            errors.append(Linter.Error.untidy(file))
        if not Linter._ensure_static_typing(file):
            errors.append(Linter.Error.incorrect_type_hints(file))
        return errors

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
    def _ensure_tidy(file: str) -> bool:
        dst = os.path.join(Linter._tmp_dir(), os.path.basename(file))
        shutil.copyfile(file, dst)
        Linter.tidy([dst], False)
        return Linter._file_md5(file) == Linter._file_md5(dst)

    @staticmethod
    def _ensure_static_typing(file: str) -> bool:
        mypy_cmd = ["mypy", "--config-file", os.path.join(Dir.dot(), "mypy.ini"), file]
        return sh(mypy_cmd) == 0

    @staticmethod
    def _tmp_dir() -> str:
        return os.path.join(Dir.tmp(), "linter")

    @staticmethod
    def _file_md5(file: str) -> str:
        md5 = hashlib.md5()
        with open(file, "rb") as f:
            md5.update(f.read())
        return md5.hexdigest()
