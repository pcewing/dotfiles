#!/usr/bin/env python3

import sys


def out(s: str) -> None:
    sys.stdout.write(s)


def main() -> None:
    for i in range(2):
        for j in range(30, 38):
            for k in range(40, 48):
                out(f"\33[{i};{j};{k}m{i};{j};{k}\33[m ")
            out("\n")


if __name__ == "__main__":
    main()
