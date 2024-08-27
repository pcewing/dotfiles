#!/usr/bin/env python

import argparse
import json
import os
import subprocess
from typing import Optional

from lib.common.file_walker import FileWalker
from lib.common.util import home, sh


class Config:
    _PATH = None

    @staticmethod
    def load() -> dict[str, str]:
        if not os.path.exists(Config._path()):
            Config._init()
        with open(Config._path(), "r") as f:
            return json.loads(f.read())

    @staticmethod
    def _init() -> None:
        os.makedirs(os.path.dirname(Config._path()), exist_ok=True)
        with open(Config._path(), "w") as f:
            f.write(json.dumps(Config._default(), indent="    "))

    @staticmethod
    def _path():
        if Config._PATH is None:
            Config._PATH = f"{home()}/.config/fd/config.json"
        return Config._PATH

    @staticmethod
    def _default() -> dict[str, any]:
        return {
            "update": {
                "git_search_paths": [
                    "~/src"
                ]
            }
        }


RegistryEntry = dict[str, str]
RegistryEntries = dict[str, RegistryEntry]


class Registry:
    _PATH = None

    @staticmethod
    def load() -> RegistryEntries:
        try:
            with open(Registry.path(), "r") as f:
                return json.loads(f.read())
        except FileNotFoundError:
            return {}

    @staticmethod
    def store(entries: RegistryEntries):
        os.makedirs(os.path.dirname(Registry.path()), exist_ok=True)
        with open(Registry.path(), "w") as f:
            f.write(json.dumps(entries, indent="    "))

    @staticmethod
    def path():
        if Registry._PATH is None:
            Registry._PATH = f"{home()}/.local/share/fd/registry.json"
        return Registry._PATH


def add_fd_parser(parent: argparse.ArgumentParser) -> None:
    parser = parent.add_parser("fd", help="TODO")

    subparsers = parser.add_subparsers(help="commands")

    cmd_parser_choose = subparsers.add_parser(
        "choose", help="Use FZF to choose a directory from the registry"
    )
    cmd_parser_choose.add_argument("query", default="", nargs="?")
    cmd_parser_choose.set_defaults(func=cmd_fd_choose)

    cmd_parser_add = subparsers.add_parser(
        "add", help="Add current working directory to registry"
    )
    cmd_parser_add.add_argument("key", default=None, nargs="?")
    cmd_parser_add.add_argument("--category", default="")
    cmd_parser_add.set_defaults(func=cmd_add)

    cmd_parser_edit = subparsers.add_parser(
        "edit", help="Open the registry file in an editor"
    )
    cmd_parser_edit.set_defaults(func=cmd_edit)

    cmd_parser_update = subparsers.add_parser("update", help="Update the registry")
    cmd_parser_update.set_defaults(func=cmd_update)


def cmd_fd_choose(args: argparse.Namespace) -> None:
    entries = Registry.load()

    if len(entries) == 0:
        entries["~/Documents"] = {"path": f"{home()}/Documents", "category": ""}
        entries["~/Downloads"] = {"path": f"{home()}/Downloads", "category": ""}
        Registry.store(entries)

    stdin = "\n".join(entries.keys())

    selected_key = None
    cmd = ["fzf", "--query", args.query]
    try:
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE, text=True)
        selected_key = p.communicate(input=stdin)[0].strip()
    except FileNotFoundError as e:
        raise Exception("FZF not installed or not in PATH") from e

    if p.returncode != 0:
        return

    if selected_key not in entries:
        raise Exception(f"Directory {selected_key} does not exist")

    # We can't actually change directories in this script because it would only
    # affect the Python process and not the shell so just print the selection.
    # Use a bash function/alias to call this and then `cd` into the result
    print(entries[selected_key]["path"])


def cmd_add(args: argparse.Namespace) -> None:
    key = args.key
    cwd = os.getcwd()

    if key is None or key == "":
        key = cwd.replace(home(), "~")

    entries = Registry.load()
    entries[key] = {"path": cwd, "category": args.category}
    Registry.store(entries)


def cmd_edit(args: argparse.Namespace) -> None:
    editor = os.getenv("EDITOR")
    if editor is None:
        editor = "nvim"
    sh([editor, Registry.path()])


def cmd_update(args: argparse.Namespace) -> None:
    config = Config.load()

    if "update" not in config:
        return

    entries = Registry.load()

    if "git_search_paths" in config["update"]:
        # Clear out old git repository entries which may no longer exist
        keys_to_delete = []
        for k, v in entries.items():
            if v["category"] == "git-repository":
                keys_to_delete.append(k)
        for key in keys_to_delete:
            del entries[key]

        git_repositories = []
        for path in config["update"]["git_search_paths"]:
            git_repositories += locate_git_repositories(path)

        for git_repository in git_repositories:
            key = git_repository.replace(home(), "~")
            if key not in entries:
                entries[key] = {"path": git_repository, "category": "git-repository"}

    Registry.store(entries)


def locate_git_repositories(path) -> None:
    if path.startswith("~/"):
        path = f"{home()}/{path[2:]}"
    if "$HOME" in path:
        path = path.replace("$HOME", home())

    git_repositories = []

    def handle_dir(
        dir: FileWalker.Directory,
    ) -> Optional[FileWalker.DirectoryHandlerResult]:
        if os.path.isdir(f"{dir.get_absolute_path()}/.git"):
            git_repositories.append(dir.get_absolute_path())
            return FileWalker.DirectoryHandlerResult(skip=True)

    FileWalker.walk(
        os.path.realpath(path),
        file_handler=None,
        directory_handler=handle_dir,
    )

    return git_repositories
