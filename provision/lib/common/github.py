#!/usr/bin/env python

import json
import urllib.request

from .util import download_file


class Github:
    @staticmethod
    def get_latest_release(org: str, repo: str) -> str:
        url = f"https://api.github.com/repos/{org}/{repo}/releases/latest"
        with urllib.request.urlopen(url) as response:
            return json.loads(response.read())["tag_name"]

    def download_release_artifact(
        org: str, repo: str, release: str, file: str, path: str, dry_run: bool
    ) -> None:
        url = f"https://github.com/{org}/{repo}/releases/download/{release}/{file}"
        download_file(url, path, dry_run)
