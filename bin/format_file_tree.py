#!/usr/bin/env python3

# Rename this to `find_tree` or something and add it to dotfiles. It's
# basically the `find` shell command except it formats files in a nicer ascii
# tree format.

import argparse
import os
import sys

DOTFILES_DIR = os.getenv("DOTFILES")
if DOTFILES_DIR is None:
    raise Exception("DOTFILES environment variable not specified")
sys.path.append(os.path.join(DOTFILES_DIR, "src"))

from dot.lib.common.file_walker import FileWalker


def _walk_directory(root_dir: str) -> None:
    print(f"{root_dir}/")

    def enumerate_file(file: "FileWalker.File") -> None:
        print(f"{file.get_prefix()}{file.get_name()}")

    def enumerate_directory(directory: "FileWalker.Directory") -> None:
        print(f"{directory.get_prefix()}{directory.get_name()}/")

    FileWalker.walk(
        root_dir,
        file_handler=enumerate_file,
        directory_handler=enumerate_directory,
    )


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Print a directory tree in a nicer ascii format"
    )
    parser.add_argument("-d", "--directory", default=".", help="the directory to walk")
    return parser.parse_args()


def main():
    args = _parse_args()
    _walk_directory(args.directory)


if __name__ == "__main__":
    main()
