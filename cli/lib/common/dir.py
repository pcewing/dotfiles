#!/usr/bin/env python

import os

SCRIPT_PATH = os.path.realpath(__file__)
SCRIPT_DIR = os.path.dirname(SCRIPT_PATH)


class Dir:
    _dot = None
    _config = None
    _home = None

    @staticmethod
    def dot() -> str:
        if Dir._dot is None:
            common_dir = SCRIPT_DIR
            lib_dir = os.path.dirname(common_dir)
            cli_dir = os.path.dirname(lib_dir)
            dot_dir = os.path.dirname(cli_dir)
            Dir._dot = dot_dir
        return Dir._dot

    @staticmethod
    def config() -> str:
        if Dir._config is None:
            Dir._config = os.path.join(Dir.dot(), "config")
        return Dir._config

    @staticmethod
    def home(reload=False) -> str:
        if reload or Dir._home is None:
            home = os.getenv("HOME")
            if home is None:
                raise Exception("HOME environment variable is missing")
            Dir._home = home
        return Dir._home