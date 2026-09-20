#!/usr/bin/env python

import argparse
import difflib
import os
import sys
from datetime import datetime
from typing import List, Tuple

from dot.lib.common.links import Link, Links
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


def _link_pairs(link: Link) -> List[Tuple[str, str]]:
    """Expand a link into the (repository, copy) file pairs that it manages.

    A file link is a single pair. A directory link is expanded into one pair per
    file in the repository, relative to the link source, so that directory links
    can be compared and backported file by file.
    """
    if not link.is_dir():
        return [(link.src, link.dst)]

    pairs = []
    for root, _dirs, files in os.walk(link.src):
        for name in files:
            src = os.path.join(root, name)
            rel = os.path.relpath(src, link.src)
            pairs.append((src, os.path.join(link.dst, rel)))
    return pairs


def _unmanaged_copy_files(link: Link) -> List[str]:
    """Return files in a directory link's copy that the repository does not manage."""
    if not link.is_dir() or not os.path.exists(link.dst):
        return []

    unmanaged = []
    for root, _dirs, files in os.walk(link.dst):
        for name in files:
            dst = os.path.join(root, name)
            src = os.path.join(link.src, os.path.relpath(dst, link.dst))
            if not os.path.exists(src):
                unmanaged.append(dst)
    return unmanaged


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
    unmanaged = 0

    for link in Links.get():
        if not os.path.exists(link.dst):
            missing.append(link.dst)
            continue

        for src, dst in _link_pairs(link):
            if not os.path.exists(dst):
                missing.append(dst)
                continue

            with open(src, "r") as f:
                src_lines = f.readlines()
            with open(dst, "r") as f:
                dst_lines = f.readlines()

            if src_lines == dst_lines:
                in_sync += 1
                continue

            changed.append(dst)

            print(f"Changed: {dst}")
            print(_newer_suggestion(src, dst))
            for line in difflib.unified_diff(
                src_lines, dst_lines, fromfile=src, tofile=dst
            ):
                print(line, end="")
            print()

        for dst in _unmanaged_copy_files(link):
            unmanaged += 1
            Log.warn(
                "File exists in the copy but not in the repository",
                {"path": dst},
            )

    for dst in missing:
        Log.warn("Missing destination file", {"path": dst})

    Log.info(
        "links diff complete",
        {
            "in_sync": in_sync,
            "changed": len(changed),
            "missing": len(missing),
            "unmanaged": unmanaged,
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

    pairs = []
    missing = []

    for link in Links.get():
        if not os.path.exists(link.dst):
            missing.append(link.dst)
            continue

        for src, dst in _link_pairs(link):
            if not os.path.exists(dst):
                missing.append(dst)
                continue
            pairs.append((src, dst))

    refused = [
        (src, dst)
        for src, dst in pairs
        if os.path.getmtime(src) > os.path.getmtime(dst) and _contents_differ(src, dst)
    ]

    if refused and not args.force:
        for src, dst in refused:
            Log.error(
                "Refusing to backport; the repo file is newer than the copy",
                {"repo": src, "copy": dst},
            )
        Log.error("Use --force to overwrite the repository files anyway")
        sys.exit(1)

    backported = []
    unchanged = 0
    unmanaged = 0

    for src, dst in pairs:
        with open(dst, "r") as f:
            contents = f.read()

        with open(src, "r") as f:
            current = f.read()

        if contents == current:
            unchanged += 1
            continue

        with open(src, "w") as f:
            f.write(contents)

        backported.append(dst)
        Log.info("Backported file", {"source": dst, "target": src})

    for dst in missing:
        Log.warn("Missing destination file", {"path": dst})

    for link in Links.get():
        for dst in _unmanaged_copy_files(link):
            unmanaged += 1
            Log.warn(
                "File exists in the copy but not in the repository",
                {"path": dst},
            )

    Log.info(
        "links backport complete",
        {
            "backported": len(backported),
            "unchanged": unchanged,
            "missing": len(missing),
            "unmanaged": unmanaged,
        },
    )
