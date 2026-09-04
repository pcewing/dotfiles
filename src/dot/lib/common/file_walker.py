#!/usr/bin/env python

import json
import os
from typing import Callable, Optional

from dot.lib.common.log import Log


class FileWalker:
    class Node:
        def __init__(
            self,
            root_directory: str,
            relative_path: str,
            depth: int,
            ancestor_flags: list[bool],
            is_last: bool,
        ):
            self._root = root_directory
            self._dir = os.path.dirname(relative_path)
            self._name = os.path.basename(relative_path)
            self._depth = depth
            # Whether each ancestor (excluding the root) was the last entry among its
            # siblings, used to render ASCII tree continuation bars.
            self._ancestor_flags = ancestor_flags
            self._is_last = is_last

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

        def get_depth(self) -> str:
            return self._depth

        def get_is_last(self) -> bool:
            return self._is_last

        def get_prefix(
            self, bar: str = "|  ", blank: str = "   ", connector: str = "|_ "
        ) -> str:
            """Builds the ASCII tree prefix (continuation bars plus connector)."""
            if self._depth == 0:
                return ""
            bars = "".join(
                blank if is_last else bar for is_last in self._ancestor_flags
            )
            return bars + connector

        def __str__(self) -> str:
            return json.dumps(
                {"root": self._root, "dir": self._dir, "name": self._name}
            )

    class File(Node):
        def __init__(
            self,
            root: str,
            file: str,
            depth: int,
            ancestor_flags: list[bool],
            is_last: bool,
        ):
            super().__init__(root, file, depth, ancestor_flags, is_last)

    class Directory(Node):
        def __init__(
            self,
            root: str,
            directory: str,
            depth: int,
            ancestor_flags: list[bool],
            is_last: bool,
        ):
            super().__init__(root, directory, depth, ancestor_flags, is_last)

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

    @staticmethod
    def walk(
        directory: str,
        file_handler: "FileWalker.FileHandler" = None,
        directory_handler: "FileWalker.DirectoryHandler" = None,
    ) -> None:
        ctx = FileWalker.Context(directory, file_handler, directory_handler)
        root_node = FileWalker.Directory(directory, "", 0, [], False)
        FileWalker._walk(ctx, root_node, [])

    @staticmethod
    def _walk(ctx: Context, directory: Directory, ancestor_flags: list[bool]) -> None:
        # Directories before files, alphabetically within each group.
        dir_entries = sorted(
            os.scandir(path=directory.get_absolute_path()),
            key=lambda entry: (not entry.is_dir(follow_symlinks=True), entry.name.lower()),
        )
        depth = directory.get_depth() + 1
        for index, dir_entry in enumerate(dir_entries):
            if ctx.halt:
                break
            is_last = index == len(dir_entries) - 1
            path_rel = os.path.join(directory.get_relative_path(), dir_entry.name)
            if dir_entry.is_dir(follow_symlinks=True):
                child = FileWalker.Directory(
                    ctx.root, path_rel, depth, ancestor_flags, is_last
                )
                FileWalker._handle_dir(ctx, child, ancestor_flags + [is_last])
            elif dir_entry.is_file(follow_symlinks=True):
                child = FileWalker.File(
                    ctx.root, path_rel, depth, ancestor_flags, is_last
                )
                FileWalker._handle_file(ctx, child)
            elif dir_entry.is_symlink():
                Log.debug(
                    "encountered symlink directory entry with non-existant target"
                )
            else:
                Log.warn(
                    "encountered directory entry of unknown type",
                    [("path", dir_entry.path)],
                )

    @staticmethod
    def _handle_dir(
        ctx: Context, directory: Directory, child_ancestor_flags: list[bool]
    ) -> None:
        # If no handler was provided, keep walking
        if ctx.directory_handler is None:
            FileWalker._walk(ctx, directory, child_ancestor_flags)
            return

        # If handler didn't return a result, keep walking
        result = ctx.directory_handler(directory)
        if result is None:
            FileWalker._walk(ctx, directory, child_ancestor_flags)
            return

        # If handler requested to halt, stop immediately
        ctx.halt = result.halt
        if ctx.halt:
            return

        # If handler requested to skip, do nothin
        if result.skip:
            return

        # Handler provided a result but didn't request to halt or skip
        FileWalker._walk(ctx, directory, child_ancestor_flags)

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
