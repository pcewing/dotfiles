#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
git-wdiff: Diff the working directory (or a target ref) against a diff-base worktree.

The diff-base worktree is created as a sibling of the active worktree
directory and is reused across invocations.  Because worktrees share the
same object store as the main repository, every local commit is available
immediately — no clone or fetch is required.

Usage:
    python git-wdiff.py [--diff-tool PATH] [--base-ref REF] [--target-ref REF]

Worktree naming:
    Active worktree:      D:/src/foo/
    diff-base worktree:   D:/src/foo.diff-base/
    diff-target worktree: D:/src/foo.diff-target/  (only when --target-ref is used)

Notes on Beyond Compare executables:
    BCompare.exe  -- Launches the GUI and returns immediately (default).
    BComp.exe     -- Blocks until the comparison window is closed; useful
                     when you need to wait for the diff to complete in a
                     script context.
"""

import argparse
import subprocess
import sys
from pathlib import Path

DEFAULT_DIFF_TOOL = r"C:\Program Files\Beyond Compare 5\BCompare.exe"


def run(cmd, cwd=None, check=True):
    """Run a command, print stderr on failure, and return stdout."""
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode != 0:
        cmd_str = " ".join(str(c) for c in cmd)
        print(f"Command failed: {cmd_str}", file=sys.stderr)
        if result.stderr:
            print(result.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def get_repo_root():
    """Return the root directory of the current (active) worktree."""
    root = run(["git", "rev-parse", "--show-toplevel"])
    if not root:
        print("Error: not inside a git repository.", file=sys.stderr)
        sys.exit(1)
    return Path(root)


def list_worktree_paths(repo_root):
    """Return a set of Path objects for every registered worktree."""
    output = run(["git", "worktree", "list", "--porcelain"], cwd=str(repo_root))
    paths = set()
    for line in output.splitlines():
        if line.startswith("worktree "):
            paths.add(Path(line[len("worktree "):]))
    return paths


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Diff the working directory (or a target ref) against a diff-base "
            "worktree.  The worktree(s) are created once and reused on "
            "subsequent runs."
        )
    )
    parser.add_argument(
        "--diff-tool",
        default=DEFAULT_DIFF_TOOL,
        metavar="PATH",
        help=f"Path to directory diff tool executable (default: {DEFAULT_DIFF_TOOL})",
    )
    parser.add_argument(
        "--base-ref",
        default=None,
        metavar="REF",
        help="Git ref to use as the diff base (default: HEAD of the active worktree)",
    )
    parser.add_argument(
        "--target-ref",
        default=None,
        metavar="REF",
        help=(
            "Git ref to diff against the base.  When omitted the working "
            "directory is used as the right side of the diff."
        ),
    )
    args = parser.parse_args()

    diff_tool = Path(args.diff_tool)
    if not diff_tool.is_file():
        print(f"Error: diff tool not found: {diff_tool}", file=sys.stderr)
        sys.exit(1)

    repo_root = get_repo_root()
    print(f"Repository:      {repo_root}")

    # The diff-base worktree lives next to the active worktree directory.
    diff_base = repo_root.parent / (repo_root.name + ".diff-base")
    print(f"Diff-base:       {diff_base}")

    # Resolve the base ref to a commit hash.  Using the hash avoids ambiguity
    # and works correctly in detached HEAD states.
    if args.base_ref is not None:
        head = run(["git", "rev-parse", args.base_ref], cwd=str(repo_root))
        print(f"Base ref:        {args.base_ref} ({head[:8]})")
    else:
        head = run(["git", "rev-parse", "HEAD"], cwd=str(repo_root))
        print(f"HEAD:            {head[:8]}")

    # Prune stale worktree entries (e.g. if the directory was manually deleted)
    # before querying the list so we get an accurate picture.
    run(["git", "worktree", "prune"], cwd=str(repo_root))

    registered = list_worktree_paths(repo_root)

    if diff_base not in registered:
        print("Creating diff-base worktree...")
        run(
            ["git", "worktree", "add", "--detach", str(diff_base), head],
            cwd=str(repo_root),
        )
        print("Worktree created.")
    else:
        print("Diff-base worktree already exists, updating checkout...")
        run(["git", "checkout", "--detach", head], cwd=str(diff_base))

    # Determine the right side of the diff.
    if args.target_ref is not None:
        target_commit = run(
            ["git", "rev-parse", args.target_ref], cwd=str(repo_root)
        )
        print(f"Target ref:      {args.target_ref} ({target_commit[:8]})")

        diff_target = repo_root.parent / (repo_root.name + ".diff-target")
        print(f"Diff-target:     {diff_target}")

        if diff_target not in registered:
            print("Creating diff-target worktree...")
            run(
                ["git", "worktree", "add", "--detach", str(diff_target), target_commit],
                cwd=str(repo_root),
            )
            print("Worktree created.")
        else:
            print("Diff-target worktree already exists, updating checkout...")
            run(["git", "checkout", "--detach", target_commit], cwd=str(diff_target))

        right_side = diff_target
    else:
        right_side = repo_root

    # Launch the diff tool: left = base, right = target (or working directory).
    print(f"Launching {diff_tool.name} ...")
    subprocess.Popen([str(diff_tool), str(diff_base), str(right_side)])


if __name__ == "__main__":
    main()
