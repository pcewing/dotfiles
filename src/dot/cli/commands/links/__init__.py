#!/usr/bin/env python

import argparse
import difflib
import os
import sys
from datetime import datetime

from dot.lib.common.links import Links
from dot.lib.common.log import Log
from dot.lib.common.os import OperatingSystem


def add_links_parser(parent: argparse.ArgumentParser) -> None:
    parser = parent.add_parser(
        "links",
        help="Manage dotfile links",
    )

    subparsers = parser.add_subparsers(help="commands")

    cmd_parser_init = subparsers.add_parser(
        "init",
        help="Create links to dotfiles",
    )
    cmd_parser_init.set_defaults(func=cmd_init)

    cmd_parser_clean = subparsers.add_parser(
        "clean",
        help="Clean up links to dotfiles",
    )
    cmd_parser_clean.set_defaults(func=cmd_clean)

    cmd_parser_diff = subparsers.add_parser(
        "diff",
        help="Diff dotfiles against the links placed on disk",
    )
    cmd_parser_diff.set_defaults(func=cmd_diff)

    cmd_parser_backport = subparsers.add_parser(
        "backport",
        help="Copy the contents of on-disk links back into the repo",
    )
    cmd_parser_backport.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Overwrite repository files even when they are newer than their copies",
    )
    cmd_parser_backport.set_defaults(func=cmd_backport)


def cmd_init(args: argparse.Namespace) -> None:
    Log.info("Creating symlinks")
    Log.info("=================")

    links = Links.get()
    for link in links:
        link.create()


def cmd_clean(args: argparse.Namespace) -> None:
    Log.info("Removing symlinks")
    Log.info("==============================")

    links = Links.get()
    for link in links:
        link.delete()

    if OperatingSystem.get().is_windows():
        return

    Log.info("Removing symlink for sway-user.desktop requires root priveleges; run:")
    Log.info('sudo rm "/usr/share/wayland-sessions/sway-user.desktop"')


def _fmt_time(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")


def _newer_suggestion(src: str, dst: str) -> str:
    src_mtime = os.path.getmtime(src)
    dst_mtime = os.path.getmtime(dst)

    if src_mtime == dst_mtime:
        return "  suggest: timestamps are equal; both files may have been edited"
    if src_mtime > dst_mtime:
        return (
            "  suggest: repo is newer "
            f"({_fmt_time(src_mtime)} vs {_fmt_time(dst_mtime)})"
        )
    return (
        "  suggest: copy is newer "
        f"({_fmt_time(dst_mtime)} vs {_fmt_time(src_mtime)})"
    )


def cmd_diff(args: argparse.Namespace) -> None:
    if not OperatingSystem.get().is_windows():
        raise NotImplementedError("links diff is only supported on Windows")

    in_sync = 0
    changed = []
    missing = []

    for link in Links.get():
        if not os.path.exists(link.dst):
            missing.append(link)
            continue

        with open(link.src, "r") as f:
            src_lines = f.readlines()
        with open(link.dst, "r") as f:
            dst_lines = f.readlines()

        if src_lines == dst_lines:
            in_sync += 1
            continue

        changed.append(link)

        print(f"Changed: {link.dst}")
        print(_newer_suggestion(link.src, link.dst))
        for line in difflib.unified_diff(
            src_lines, dst_lines, fromfile=link.src, tofile=link.dst
        ):
            print(line, end="")
        print()

    for link in missing:
        Log.warn("Missing destination file", {"path": link.dst})

    Log.info(
        "links diff complete",
        {
            "in_sync": in_sync,
            "changed": len(changed),
            "missing": len(missing),
        },
    )


def _contents_differ(src: str, dst: str) -> bool:
    with open(src, "r") as f:
        src_contents = f.read()
    with open(dst, "r") as f:
        dst_contents = f.read()
    return src_contents != dst_contents


def cmd_backport(args: argparse.Namespace) -> None:
    if not OperatingSystem.get().is_windows():
        raise NotImplementedError("links backport is only supported on Windows")

    refused = [
        link
        for link in Links.get()
        if os.path.exists(link.dst)
        and os.path.getmtime(link.src) > os.path.getmtime(link.dst)
        and _contents_differ(link.src, link.dst)
    ]

    if refused and not args.force:
        for link in refused:
            Log.error(
                "Refusing to backport; the repo file is newer than the copy",
                {"repo": link.src, "copy": link.dst},
            )
        Log.error("Use --force to overwrite the repository files anyway")
        sys.exit(1)

    backported = []
    unchanged = 0
    missing = []

    for link in Links.get():
        if not os.path.exists(link.dst):
            missing.append(link)
            continue

        with open(link.dst, "r") as f:
            contents = f.read()

        with open(link.src, "r") as f:
            current = f.read()

        if contents == current:
            unchanged += 1
            continue

        with open(link.src, "w") as f:
            f.write(contents)

        backported.append(link)
        Log.info("Backported file", {"source": link.dst, "target": link.src})

    for link in missing:
        Log.warn("Missing destination file", {"path": link.dst})

    Log.info(
        "links backport complete",
        {
            "backported": len(backported),
            "unchanged": unchanged,
            "missing": len(missing),
        },
    )
