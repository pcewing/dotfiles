#!/usr/bin/env python

import argparse
import os

SCRIPT_PATH = os.path.realpath(__file__)
SCRIPT_DIR = os.path.dirname(SCRIPT_PATH)


def parse_args():
    parser = argparse.ArgumentParser(description="TODO")
    parser.add_argument("-o", "--output", default="TODO", help="TODO")
    parser.add_argument("--verbose", action="store_true", help="TODO")
    return parser.parse_args()


def main():
    args = parse_args()


if __name__ == "__main__":
    main()
