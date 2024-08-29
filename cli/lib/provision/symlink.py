#!/usr/bin/env python

from lib.common.log import Log
from lib.common.shell import Shell


class Symlink:
    @staticmethod
    def create(source: str, target: str, sudo: bool, dry_run: bool) -> None:
        Log.info("creating symlink", {"source": source, "target": target})

        if dry_run:
            Log.info("skipping symlink creation", {"reason": "dry run"})
            return

        if not os.path.isfile(source):
            raise Exception(f"Symlink source doesn't exist: {source}")

        # Delete existing symlink target if there is one
        Shell.rm(
            path=target,
            recursive=False,
            force=True,
            sudo=sudo,
            dry_run=dry_run,
        )

        # Create the symlink
        Shell.ln(
            source=source,
            target=target,
            sudo=sudo,
            dry_run=dry_run,
        )
