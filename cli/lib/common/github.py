#!/usr/bin/env python

import json
import urllib.request

from .util import download_file


class Github:
    # TODO: Make a GithubRelease class that this can return that makes it easy
    # to convert between the raw release name and a Semver
    @staticmethod
    def get_latest_release(org: str, repo: str) -> str:
        url = f"https://api.github.com/repos/{org}/{repo}/releases/latest"
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read())["tag_name"]

    @staticmethod
    def get_releases(org: str, repo: str) -> list[str]:
        url = f"https://api.github.com/repos/{org}/{repo}/releases"
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read())

    @staticmethod
    def get_tags(org: str, repo: str) -> list[str]:
        url = f"https://api.github.com/repos/{org}/{repo}/tags"
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read())

    @staticmethod
    def download_release_artifact(
        org: str,
        repo: str,
        release: str,
        file: str,
        path: str,
        create_dir: bool,
        sudo: bool,
        force: bool,
        dry_run: bool,
    ) -> None:
        url = f"https://github.com/{org}/{repo}/releases/download/{release}/{file}"
        download_file(url, path, sudo, force, dry_run)
