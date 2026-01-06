#!/usr/bin/env python

import json
import os
from typing import Callable, Optional

from lib.common.log import Log


class FileWalker:
    class Node:
        def __init__(self, root_directory: str, relative_path: str):
            self._root = root_directory
            self._dir = os.path.dirname(relative_path)
            self._name = os.path.basename(relative_path)

            # For optimization purposes, store these off to avoid further allocations
            self._path_absolute = os.path.join(self._root, relative_path)
            self._path_relative = relative_path

        def get_root(self) -> str:
            return self._root

        def get_name(self) -> str:
            return self._name

        def get_relative_path(self) -> str:
            return self._path_relative

        def get_absolute_path(self) -> str:
            return self._path_absolute

        def __str__(self) -> str:
            return json.dumps(
                {"root": self._root, "dir": self._dir, "name": self._name}
            )

    class File(Node):
        def __init__(self, root: str, file: str):
            super().__init__(root, file)

    class Directory(Node):
        def __init__(self, root: str, directory: str):
            super().__init__(root, directory)

    class DirectoryHandlerResult:
        def __init__(self, halt: bool = False, skip: bool = False) -> None:
            self.halt = halt
            self.skip = skip

    class FileHandlerResult:
        def __init__(self, halt: bool = False) -> None:
            self.halt = halt

    class Enumeration:
        def __init__(self) -> None:
            self._files: list["FileWalker.File"] = []
            self._directories: list["FileWalker.Directory"] = []

        def add_file(self, file: "FileWalker.File") -> None:
            self._files.append(file)

        def add_directory(self, directory: "FileWalker.Directory") -> None:
            self._directories.append(directory)

        def get_files(self) -> list["FileWalker.File"]:
            return self._files

        def get_directories(self) -> list["FileWalker.Directory"]:
            return self._directories

        def get_nodes(self) -> list["FileWalker.Node"]:
            # TODO: How do I make this one line without angering mypy?
            nodes: list["FileWalker.Node"] = []
            nodes += self._files
            nodes += self._directories
            return nodes

    FileHandler = Optional[Callable[[File], Optional[FileHandlerResult]]]
    DirectoryHandler = Optional[Callable[[Directory], Optional[DirectoryHandlerResult]]]

    class Context:
        def __init__(
            self,
            root: str,
            file_handler: "FileWalker.FileHandler" = None,
            directory_handler: "FileWalker.DirectoryHandler" = None,
        ):
            self.root = root
            self.file_handler = file_handler
            self.directory_handler = directory_handler
            self.halt = False
            self.base_path = root + "/"

    @staticmethod
    def walk(
        directory: str,
        file_handler: "FileWalker.FileHandler" = None,
        directory_handler: "FileWalker.DirectoryHandler" = None,
    ) -> None:
        ctx = FileWalker.Context(directory, file_handler, directory_handler)
        FileWalker._walk(ctx, FileWalker.Directory(directory, ""))

    @staticmethod
    def _walk(ctx: Context, directory: Directory) -> None:
        dir_entries = os.scandir(path=directory.get_absolute_path())
        for dir_entry in dir_entries:
            if ctx.halt:
                break
            path_rel = dir_entry.path.replace(ctx.base_path, "")
            if dir_entry.is_dir(follow_symlinks=True):
                FileWalker._handle_dir(ctx, FileWalker.Directory(ctx.root, path_rel))
            elif dir_entry.is_file(follow_symlinks=True):
                FileWalker._handle_file(ctx, FileWalker.File(ctx.root, path_rel))
            elif dir_entry.is_symlink():
                # BUG FIX: Fixed typo "non-existant" -> "non-existent"
                Log.debug(
                    "encountered symlink directory entry with non-existent target"
                )
            else:
                Log.warn(
                    "encountered directory entry of unknown type",
                    [("path", dir_entry.path)],
                )

    @staticmethod
    def _handle_dir(ctx: Context, directory: Directory) -> None:
        # If no handler was provided, keep walking
        if ctx.directory_handler is None:
            FileWalker._walk(ctx, directory)
            return

        # If handler didn't return a result, keep walking
        result = ctx.directory_handler(directory)
        if result is None:
            FileWalker._walk(ctx, directory)
            return

        # If handler requested to halt, stop immediately
        ctx.halt = result.halt
        if ctx.halt:
            return

        # If handler requested to skip, do nothing
        if result.skip:
            return

        # Handler provided a result but didn't request to halt or skip
        FileWalker._walk(ctx, directory)

    @staticmethod
    def _handle_file(ctx: Context, file: File) -> None:
        # If no handler was provided, there's nothing to do
        if ctx.file_handler is None:
            return

        # If handler didn't return a result, keep walking
        result = ctx.file_handler(file)
        if result is None:
            return

        # If handler requested to halt, stop immediately
        ctx.halt = result.halt

    @staticmethod
    def enumerate(
        directory: str, files: bool = True, directories: bool = True
    ) -> Enumeration:
        enumeration = FileWalker.Enumeration()

        def enumerate_file(file: "FileWalker.File") -> None:
            enumeration.add_file(file)

        def enumerate_directory(directory: "FileWalker.Directory") -> None:
            enumeration.add_directory(directory)

        file_handler = enumerate_file if files else None
        directory_handler = enumerate_directory if directories else None

        FileWalker.walk(
            directory, file_handler=file_handler, directory_handler=directory_handler
        )
        return enumeration
