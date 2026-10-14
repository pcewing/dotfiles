#!/usr/bin/env python3

# This script will clone all repositories owned by the specified user.
#
# Given that username/password authentication to the GitHub API was deprecated,
# the script authenticates via a personal access token. This can either be set
# using the GITHUB_API_TOKEN environment variable or via the --token option,
# the option taking precedent
#
# Usage:
#     clone.py [options]
#
# Examples:
#     GITHUB_API_TOKEN="26f4f4147352b7c943a62d43c9d5684d7a9a3669" clone.py
#     clone.py --token="26f4f4147352b7c943a62d43c9d5684d7a9a3669"
#
# For more details:
#     clone.py -h

import argparse
import json
import os
import re
import subprocess
import urllib.request
from typing import Any

# IGNORE_ORGS is a list of orgs which should not be cloned.
IGNORE_ORGS = ["hashicorp"]


class Repo:
    def __init__(self, org: str = "", name: str = "", url: str = "") -> None:
        self.org = org
        self.name = name
        self.url = url


def clone(src_dir: str, repo: Repo, dry_run: bool) -> None:
    os.makedirs(repo.org, exist_ok=True)

    global IGNORE_ORGS
    if repo.org in IGNORE_ORGS:
        print(
            f"Repo {repo.org}/{repo.name} is in an org which should be ignored, skipping..."
        )
        return

    path = os.path.join(src_dir, repo.org, repo.name)
    if os.path.exists(path):
        print(f"Repo path {repo.org}/{repo.name} already exists, skipping...")
        return

    if dry_run:
        print(f"git clone {repo.url} {path}")
    else:
        subprocess.run(["git", "clone", repo.url, path])


def get_page(url: str, token: str) -> tuple[str | None, list[dict[str, Any]]]:
    request = urllib.request.Request(url)
    request.add_header("Authorization", f"token {token}")

    with urllib.request.urlopen(request) as response:
        header = response.getheader("Link")
        matches = re.findall('.*<(.*)>; rel="next".*', header)
        next_page_url = None
        if len(matches) > 0:
            next_page_url = matches[0]
        return (next_page_url, json.loads(response.read()))


def get_repo_data(token: str) -> list[dict[str, Any]]:
    (next_page_url, data) = get_page("https://api.github.com/user/repos", token)

    while next_page_url is not None:
        (next_page_url, page_data) = get_page(next_page_url, token)
        data += page_data

    return data


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Clone a user's git repositories.")
    parser.add_argument(
        "--dry-run",
        dest="dry_run",
        action="store_true",
        help="Print actions without running them",
    )
    parser.add_argument(
        "--source-directory",
        dest="src_dir",
        type=str,
        default="$HOME/src/github",
        help="The base source directory to clone to",
    )
    parser.add_argument(
        "--token",
        dest="token",
        type=str,
        default=None,
        help="The personal access token used to authenticate",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    src_dir = os.path.expandvars(args.src_dir)

    token = args.token
    if token is None:
        token = os.getenv("GITHUB_API_TOKEN")
        if token is None:
            print("No GITHUB_API_TOKEN provided")
            exit(1)

    data = get_repo_data(token)

    repos = [Repo(r["owner"]["login"], r["name"], r["ssh_url"]) for r in data]

    for repo in repos:
        clone(src_dir, repo, args.dry_run)


if __name__ == "__main__":
    main()
