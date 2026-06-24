#!/usr/bin/env python3
"""
Rewrite git commit authors across the entire current branch history.

Useful for:
  - Fixing commits accidentally made from the wrong username/email
  - Replacing scraped-able emails with public-safe aliases

Usage:
    git-amend-authors.py --discover       # List all unique authors; no changes made
    git-amend-authors.py --dry-run        # Preview which commits would be amended
    git-amend-authors.py                  # Apply AUTHOR_MAP to the branch history

After running, force-push to update the remote:
    git push --force-with-lease
"""

import argparse
import re
import subprocess
import sys

# =============================================================================
# Configure author rewrites here.
#
# Key:   the original author identity as it appears in git log ("Name <email>")
# Value: the replacement identity to use instead
#
# Examples:
#   "Work Name <work@company.com>":       "Personal Name <me@personal.com>",
#   "Personal Name <real@personal.com>":  "Personal Name <alias@users.noreply.github.com>",
# =============================================================================
AUTHOR_MAP: dict[str, str] = {
    # "Old Name <old@email.com>": "New Name <new@email.com>",
    "Paul Ewing <pewing@blizzard.com>": "Paul Ewing <pcewing00@gmail.com>",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_author(author_str: str) -> tuple[str, str]:
    """Parse 'Name <email>' into (name, email). Raises ValueError on bad input."""
    match = re.match(r"^(.+?)\s*<([^>]+)>$", author_str.strip())
    if not match:
        sys.exit(
            f"error: invalid author format {author_str!r}\n"
            "       Expected: 'Display Name <email@example.com>'"
        )
    return match.group(1).strip(), match.group(2).strip()


def git(*args: str, capture: bool = False) -> subprocess.CompletedProcess:
    """Run a git command, exiting with an error message on failure."""
    cmd = ["git", *args]
    try:
        return subprocess.run(
            cmd,
            check=True,
            capture_output=capture,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip() if exc.stderr else ""
        sys.exit(f"error: git command failed: {' '.join(cmd)}\n{stderr}")
    except FileNotFoundError:
        sys.exit("error: 'git' executable not found in PATH")


def assert_git_repo() -> None:
    git("rev-parse", "--git-dir", capture=True)


def get_commit_authors() -> list[tuple[str, str, str]]:
    """Return [(hash, name, email), ...] for every commit on the current branch."""
    result = git("log", "--format=%H\x1f%an\x1f%ae", capture=True)
    entries: list[tuple[str, str, str]] = []
    for line in result.stdout.splitlines():
        parts = line.split("\x1f")
        if len(parts) == 3:
            entries.append((parts[0], parts[1], parts[2]))
    return entries


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_discover() -> None:
    """Print all unique authors in the branch history with commit counts."""
    entries = get_commit_authors()
    if not entries:
        print("No commits found on the current branch.")
        return

    counts: dict[str, int] = {}
    for _, name, email in entries:
        key = f"{name} <{email}>"
        counts[key] = counts.get(key, 0) + 1

    print(f"Found {len(counts)} unique author(s) across {len(entries)} commit(s):\n")
    width = len(str(max(counts.values())))
    for author, count in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {count:{width}d}  {author}")


def cmd_amend(author_map: dict[str, str], *, dry_run: bool) -> None:
    """Rewrite commits according to author_map."""
    if not author_map:
        sys.exit(
            "error: AUTHOR_MAP is empty.\n"
            "       Add at least one entry to the script before running."
        )

    # Validate every mapping entry up front.
    parsed: dict[tuple[str, str], tuple[str, str]] = {}
    for old_str, new_str in author_map.items():
        old = parse_author(old_str)
        new = parse_author(new_str)
        parsed[old] = new

    # Identify affected commits.
    entries = get_commit_authors()
    affected: list[tuple[str, str, str, str]] = []  # (short_hash, old_id, new_name, new_email)
    for commit_hash, name, email in entries:
        new = parsed.get((name, email))
        if new is not None:
            old_id = f"{name} <{email}>"
            new_id = f"{new[0]} <{new[1]}>"
            affected.append((commit_hash[:8], old_id, new_id, commit_hash))

    if not affected:
        print("No commits match any entry in AUTHOR_MAP — nothing to do.")
        return

    print(f"{'Would amend' if dry_run else 'Amending'} {len(affected)} commit(s):\n")
    for short_hash, old_id, new_id, _ in affected:
        print(f"  {short_hash}  {old_id}")
        print(f"          -> {new_id}")

    if dry_run:
        print("\n(dry-run: no changes made)")
        return

    # Build the env-filter shell script.  Each mapping produces an if-block
    # that matches on email (primary key) and name, then exports the new values
    # for both the author and committer fields.
    blocks: list[str] = []
    for (old_name, old_email), (new_name, new_email) in parsed.items():
        # Single-quote the values and escape any single quotes inside them.
        def sq(s: str) -> str:
            return "'" + s.replace("'", "'\\''") + "'"

        block = (
            f"if [ \"$GIT_AUTHOR_EMAIL\" = {sq(old_email)} ] && "
            f"[ \"$GIT_AUTHOR_NAME\" = {sq(old_name)} ]; then\n"
            f"    GIT_AUTHOR_NAME={sq(new_name)}\n"
            f"    GIT_AUTHOR_EMAIL={sq(new_email)}\n"
            f"    GIT_COMMITTER_NAME={sq(new_name)}\n"
            f"    GIT_COMMITTER_EMAIL={sq(new_email)}\n"
            f"    export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL "
            f"GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL\n"
            f"fi"
        )
        blocks.append(block)

    filter_script = "\n".join(blocks)

    print()
    # FILTER_BRANCH_SQUELCH_WARNING suppresses the advisory recommending
    # git-filter-repo; for a simple env-filter author rewrite it is not needed.
    import os
    env = {**os.environ, "FILTER_BRANCH_SQUELCH_WARNING": "1"}
    git("filter-branch", "-f", "--env-filter", filter_script, "--", "HEAD", env=env)
    print("\nDone. Run 'git push --force-with-lease' to update the remote.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--discover",
        action="store_true",
        help="List all unique authors in the commit history; make no changes.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show which commits would be amended without modifying any history.",
    )
    args = parser.parse_args()

    assert_git_repo()

    if args.discover:
        if args.dry_run:
            parser.error("--dry-run has no effect with --discover")
        cmd_discover()
    else:
        cmd_amend(AUTHOR_MAP, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
