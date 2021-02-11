#!/usr/bin/env python3

import sys


def out(s: str) -> None:
    sys.stdout.write(s)


def main() -> None:
    for i in range(2):
        for j in range(30, 38):
            for k in range(40, 48):
                out("\33[%d;%d;%dm%d;%d;%d\33[m " % (i, j, k, i, j, k))
            out("\n")


if __name__ == "__main__":
    main()
