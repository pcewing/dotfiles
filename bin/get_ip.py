#!/usr/bin/env python

import socket


def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    print(s.getsockname()[0])
    s.close()
    return 0


if __name__ == "__main__":
    exit(main())
