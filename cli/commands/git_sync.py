#!/usr/bin/env python

import argparse
import json
import random
import string

from lib.common.git import Git, GitCommit
from lib.common.log import Log
from lib.common.typing import StringOrNone

# TODO: Initial rough implementation is does and a few main cases are tested
# but this needs some cleanup now:
# - Clean up all the unnecessary logging; added this to make testing things
#   easier but now it's just way too verbose and annoying
# - Add a more descriptive help message
# - Break up main function so this is more readable
# - Add a '-m/--message' flag to allow users to specify a commit message


def add_git_sync_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "git-sync",
        # TODO: Add a more descriptive help message
        help="Simple sync to a remote git repository",
    )
    parser.add_argument(
        "-d", "--dry-run", action="store_true", help="Dry run the command"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Extra verbose output"
    )
    parser.set_defaults(func=cmd_git_sync)


def generate_temporary_branch_name(length: int = 8):
    characters = string.ascii_lowercase + string.digits
    random_string = "".join(random.choice(characters) for _ in range(length))
    return f"temp-{random_string}"


# Find the most recent matching commit between the local and remote
# repositories. Returns the index into both arrays of that commit.
def find_common_commit(
    local_commits: list[GitCommit], remote_commits: list[GitCommit]
) -> tuple[int, int]:
    remote_commits_dict = {}
    for i in range(len(remote_commits)):
        remote_commit = remote_commits[i]
        remote_commits_dict[remote_commit.hash] = i

    local_commit_index = None
    remote_commit_index = None

    for i in range(len(local_commits)):
        local_commit = local_commits[i]
        remote_commit_index = remote_commits_dict.get(local_commit.hash)
        if remote_commit_index is None:
            continue
        local_commit_index = i
        remote_commit_index = remote_commit_index
        break

    if remote_commit_index is None:
        raise Exception(
            "Failed to find a common commit between the local and remote repositories"
        )

    common_commit = local_commits[local_commit_index]
    Log.info(
        "common commit found",
        {"hash": common_commit.hash, "message": common_commit.message},
    )

    return local_commit_index, remote_commit_index


def resolve_local_changes(current_branch: str, dry_run: bool) -> StringOrNone:
    git_status = Git.status()

    Log.info("Checking if there are local changes that need to be committed")
    if not git_status.is_commit_required():
        Log.info("There are no local changes that need to be committed")
        return None

    Log.info("There are local changes that need to be committed")

    Log.info("Creating a temporary branch to commit local changes into")

    Log.info("Generating branch name")
    temp_branch = generate_temporary_branch_name()
    Log.info(f"Generated branch name is {temp_branch}")

    Log.info("Creating temporary branch")
    if not dry_run:
        Git.create_branch(temp_branch)
    Log.info("Temporary branch created")

    Log.info("Checking out temporary branch")
    if not dry_run:
        Git.checkout(temp_branch)
    Log.info("Temporary branch checked out")

    # If there are unstaged modified or untracked files, we need to stage them
    Log.info("Checking if there are unstaged changes that need to be staged")
    if git_status.is_add_required():
        Log.info("There are unstaged modifications or additions, staging changes")
        if not dry_run:
            Git.add_all()
    else:
        Log.info("There are no unstaged changes that need to be staged")

    Log.info("There are staged modifications or additions, commiting changes")
    if not dry_run:
        Git.commit("[Auto] Syncing local changes with remote")
    Log.info("Changes were committed")

    Log.info("Identifying hash of the temporary commit")
    temp_commit_hash = "abcd1234abcd1234abcd1234abcd1234abcd1234"
    if not dry_run:
        temp_commit_hash = Git.get_commits(limit=1)[0].hash
    Log.info(f"Temporary commit hash = {temp_commit_hash}")

    Log.info(f"Checking out the original branch ({current_branch.name})")
    if not dry_run:
        Git.checkout(current_branch.name)
    Log.info(f"Checked out the original branch")

    return temp_commit_hash


def cmd_git_sync(args: argparse.Namespace) -> None:
    Log.info("Identifying current branch")
    current_branch = Git.get_current_branch()
    Log.info(f"Current branch is {current_branch}")

    remote = current_branch.tracking.split("/")[0]

    # If there are local changes that need to be committed, commit them into a
    # temp branch first.
    temp_commit_hash = resolve_local_changes(current_branch, args.dry_run)

    Log.info("Fetching all changes from remotes")
    Git.fetch_all()

    # Get the commits from both the local and remote repository
    local_commits = Git.get_commits()
    remote_commits = Git.get_commits(f"{remote}/{current_branch.name}")

    if args.verbose:
        print_commits(local_commits)
        print_commits(remote_commits)

    # Find the most recent matching commit between the local and remote
    local_commit_index, remote_commit_index = find_common_commit(
        local_commits, remote_commits
    )

    print(
        local_commit_index,
        remote_commit_index,
        len(local_commits),
        len(remote_commits),
    )

    # Get the number of commits the local repository has that the remote is
    # missing
    push_required = temp_commit_hash is not None
    local_ahead_count = local_commit_index
    if local_ahead_count > 0:
        Log.info("Local repository has commits that the remote is missing")
        push_required = True

    # Get the number of commits the remote repository has that the local is
    # missing
    pull_required = False
    remote_ahead_count = remote_commit_index
    if remote_ahead_count > 0:
        Log.info("Remote has commits that the local repository is missing")
        pull_required = True

    # Pull remote commits if we need to
    if pull_required:
        Log.info("pulling from remote")
        if not args.dry_run:
            Git.pull(remote, current_branch.name, rebase=True)

    # If we committed local changes to a temp branch, cherry-pick that back in
    if temp_commit_hash is not None:
        Log.info("cherry-picking temporary commit")
        if not args.dry_run:
            Git.cherry_pick(temp_commit_hash)

    if push_required:
        Log.info("pushing to remote")
        if not args.dry_run:
            Git.push(remote, current_branch.name)


def print_commits(commits: list[GitCommit]):
    d = {"commits": [c.to_dict() for c in commits]}
    print(json.dumps(d, indent=4))
