#!/usr/bin/env bash

# Rename this to `find_tree` or something and add it to dotfiles. It's
# basically the `find` shell command except it formats files in a nicer ascii
# tree format.

# TODO: There's one bug in formatting. It currently looks like this:
# foo/
# |_ bar/
# |  |_ bar.txt
# |_ baz/
# |  |_ qux/
# |  |  |_ qux.txt
# 
# But it should look like this:
# 
# foo/
# |_ bar/
# |  |_ bar.txt
# |_ baz/
#    |_ qux/
#       |_ qux.txt


import os
import sys

DOTFILES_DIR = os.getenv("DOTFILES")
if DOTFILES_DIR is None:
    raise Exception("DOTFILES environment variable not specified")
sys.path.append(os.path.join(DOTFILES_DIR, "cli"))

from lib.common.file_walker import FileWalker


def build_tree(paths):
    """Builds a nested dictionary from a list of file paths."""
    tree = {}
    for path in paths:
        path = path.strip()
        if not path:
            continue
        parts = path.split("/")
        current = tree
        for part in parts:
            if part not in current:
                current[part] = {}
            current = current[part]
    return tree


def print_tree(tree, depth=0):
    """Recursively prints the tree matching the user's specific format constraints.

    Directories and files are sorted alphabetically, but all directories are
    forced to list before files.
    """
    # Separate current level items into directories and files
    # An item is a file if its subtree dictionary is empty
    dirs = []
    files = []

    for name, subtree in tree.items():
        if subtree:  # Has children -> Directory
            dirs.append(name)
        else:  # No children -> File
            files.append(name)

    # Sort both groups alphabetically
    dirs.sort()
    files.sort()

    # Combine them so directories always appear before files
    sorted_items = dirs + files

    for name in sorted_items:
        # Create the custom visual nesting prefix
        if depth == 0:
            prefix = ""
        else:
            prefix = "|  " * (depth - 1) + "|_ "

        if tree[name]:
            print(f"{prefix}{name}/")
        else:
            print(f"{prefix}{name}")

        # Recurse into directories
        if tree[name]:
            print_tree(tree[name], depth + 1)


if __name__ == "__main__":
    # TODO: Take directory as a `-d/--directory` command line option
    file_enumeration = FileWalker.enumerate(".", files=True, directories=False)

    files = file_enumeration.get_files()

    file_paths = [f.get_relative_path() for f in files]

    # TODO: Hack, these start with ".\" on Windows which breaks the below. Fix properly
    file_paths_fixed = []
    for f in file_paths:
        file_paths_fixed.append(f[2:])


    file_tree = build_tree(file_paths_fixed)
    print_tree(file_tree)
