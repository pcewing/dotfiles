#!/usr/bin/env python

import os
import json

from .log import Log


# TODO: How does type hinting work for functions/lambda? I want to make
# FileWalkerFileHandler and FileWalkerDirectoryHandler types and enforce them.


class FileWalkerNode:
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
        return json.dumps({"root": self._root, "dir": self._dir, "name": self._name})


class FileWalkerFileNode(FileWalkerNode):
    def __init__(self, root: str, file: str):
        super().__init__(root, file)


class FileWalkerDirectoryNode(FileWalkerNode):
    def __init__(self, root: str, directory: str):
        super().__init__(root, directory)


class FileWalkerDirectoryHandlerResult:
    def __init__(self, halt=False, skip=False):
        self.halt = halt
        self.skip = skip


class FileWalkerFileHandlerResult:
    def __init__(self, halt=False):
        self.halt = halt


class FileWalkerEnumeration:
    def __init__(self):
        self._files = []
        self._directories = []

    def add_file(self, file: FileWalkerFileNode) -> None:
        self._files.append(file)

    def add_directory(self, directory: FileWalkerDirectoryNode) -> None:
        self._directories.append(directory)

    def get_files(self) -> list[FileWalkerFileNode]:
        return self._files

    def get_directories(self) -> list[FileWalkerDirectoryNode]:
        return self._directories

    def get_nodes(self) -> list[FileWalkerNode]:
        return self._files + self._directories


class FileWalkerContext:
    def __init__(self, root: str, file_handler=None, directory_handler=None):
        self.root = root
        self.file_handler = file_handler
        self.directory_handler = directory_handler
        self.halt = False
        self.base_path = root + "/"


class FileWalker:
    @staticmethod
    def walk(directory: str, file_handler=None, directory_handler=None) -> None:
        ctx = FileWalkerContext(directory, file_handler, directory_handler)
        FileWalker._walk(ctx, FileWalkerDirectoryNode(directory, ""))

    @staticmethod
    def _walk(ctx: FileWalkerContext, directory: FileWalkerDirectoryNode) -> None:
        dir_entries = os.scandir(path=directory.get_absolute_path())
        for dir_entry in dir_entries:
            if ctx.halt:
                break
            path_rel = dir_entry.path.replace(ctx.base_path, "")
            if dir_entry.is_dir(follow_symlinks=True):
                FileWalker._handle_dir(ctx, FileWalkerDirectoryNode(ctx.root, path_rel))
            elif dir_entry.is_file(follow_symlinks=True):
                FileWalker._handle_file(ctx, FileWalkerFileNode(ctx.root, path_rel))
            else:
                # TODO: This currently executes when we come across symlinks to
                # targets that no longer exist. We should probably implement a
                # mechanism to handle those.
                Log.warn(
                    "encountered directory entry of unknown type",
                    [("path", dir_entry.path)],
                )

    @staticmethod
    def _handle_dir(ctx: FileWalkerContext, directory: FileWalkerDirectoryNode):
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

        # If handler requested to skip, do nothin
        if result.skip:
            return

        # Handler provided a result but didn't request to halt or skip
        FileWalker._walk(ctx, directory)

    @staticmethod
    def _handle_file(ctx: FileWalkerContext, file: FileWalkerFileNode):
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
    ) -> FileWalkerEnumeration:
        enumeration = FileWalkerEnumeration()

        def enumerate_file(file: FileWalkerFileNode):
            enumeration.add_file(file)

        def enumerate_directory(directory: FileWalkerDirectoryNode):
            enumeration.add_directory(directory)

        file_handler = enumerate_file if files else None
        directory_handler = enumerate_directory if directories else None

        FileWalker.walk(
            directory, file_handler=file_handler, directory_handler=directory_handler
        )
        return enumeration
