#!/usr/bin/env python

import sys
import os


def main():
    path_to_add = ''
    try:
        path_to_add = os.path.expandvars(sys.argv[1])
    except:
        raise Exception('Invalid args\nUSAGE: python add_to_path.py <path>')

    path = ''
    try:
        path = os.environ['PATH']
    except:
        raise Exception('PATH environment variable is undefined')

    if path_to_add in path.split(':'):
        print(path)
    else:
        print('{0}:{1}'.format(path, path_to_add))


if __name__ == "__main__":
    main()

