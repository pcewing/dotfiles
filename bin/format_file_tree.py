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



import sys


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
    # Example input data matching your find output
    input_data = """
    src/aitools/autoprompt/generate.py
    src/aitools/autoprompt/init.py
    src/aitools/autoprompt/run.py
    src/aitools/autoprompt/__init__.py
    src/aitools/bootstrap.py
    src/aitools/cli.py
    src/aitools/common/config.py
    src/aitools/common/open_with.py
    src/aitools/common/profiles.py
    src/aitools/common/providers.py
    src/aitools/common/templating.py
    src/aitools/common/workspace.py
    src/aitools/common/__init__.py
    src/aitools/config/generate.py
    src/aitools/config/show.py
    src/aitools/config/__init__.py
    src/aitools/feature/archive.py
    src/aitools/feature/generate/address_feedback.py
    src/aitools/feature/generate/bug.py
    src/aitools/feature/generate/implement_tasks.py
    src/aitools/feature/generate/review_loop.py
    src/aitools/feature/generate/specify_tasks.py
    src/aitools/feature/generate/tdd_addendum.py
    src/aitools/feature/generate/test_plan.py
    src/aitools/feature/generate/write_tdd.py
    src/aitools/feature/generate/__init__.py
    src/aitools/feature/lib/archive.py
    src/aitools/feature/lib/common.py
    src/aitools/feature/lib/generate/address_feedback.py
    src/aitools/feature/lib/generate/bug.py
    src/aitools/feature/lib/generate/common.py
    src/aitools/feature/lib/generate/implement_tasks.py
    src/aitools/feature/lib/generate/review_loop.py
    src/aitools/feature/lib/generate/specify_tasks.py
    src/aitools/feature/lib/generate/tdd_addendum.py
    src/aitools/feature/lib/generate/test_plan.py
    src/aitools/feature/lib/generate/write_tdd.py
    src/aitools/feature/lib/generate/__init__.py
    src/aitools/feature/lib/list_archive_candidates.py
    src/aitools/feature/lib/run.py
    src/aitools/feature/lib/start.py
    src/aitools/feature/lib/__init__.py
    src/aitools/feature/list_archive_candidates.py
    src/aitools/feature/run/address_feedback.py
    src/aitools/feature/run/implement_tasks.py
    src/aitools/feature/run/specify_tasks.py
    src/aitools/feature/run/__init__.py
    src/aitools/feature/start.py
    src/aitools/feature/__init__.py
    src/health.py
    src/aitools/__init__.py
    src/aitools/__main__.py
    src/common/commit_attributions.py
    src/common/render_postprocessing.py
    src/common/__init__.py
    """

    # If paths are piped into the script, use standard input instead
    if not sys.stdin.isatty():
        paths_list = sys.stdin.read().splitlines()
    else:
        paths_list = input_data.strip().splitlines()

    file_tree = build_tree(paths_list)
    print_tree(file_tree)
