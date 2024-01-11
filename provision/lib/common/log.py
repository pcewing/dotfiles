#!/usr/bin/env python

import logging
import sys


def _log_level_from_str(log_level_str: str) -> int:
    # fmt: off
    log_levels = {
        "debug":    logging.DEBUG,
        "info":     logging.INFO,
        "warn":     logging.WARN,
        "error":    logging.ERROR,
        "crit":     logging.CRITICAL,
    }
    # fmt: on

    key = log_level_str.lower()
    if key not in log_levels:
        raise Exception("Invalid log level '{}'".format(key))
    return log_levels[key]


class Formatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        time = super(Formatter, self).formatTime(record, datefmt)
        return time.replace(",", ".")[11:]

    def format(self, record):
        # fmt: off
        level_map = {
            "DEBUG":    "DEBUG",
            "INFO":     "INFO",
            "WARNING":  "WARN",
            "ERROR":    "ERROR",
            "CRITICAL": "CRIT",
        }
        # fmt: on

        if record.levelname not in level_map:
            raise Exception("Invalid log level name " + record.levelname)

        record.levelname = level_map[record.levelname]
        return super(Formatter, self).format(record)


# Lightweight structured logging wrapper around Python's standard logging
# facilities. No effort was made to optimize performance given that this
# library is only using in tooling and automation.
class Log:
    _logger = None

    @staticmethod
    def init(level):
        if isinstance(level, str):
            level = _log_level_from_str(level)

        formatter = Formatter("%(asctime)s - %(levelname)-5s - %(message)s")

        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(formatter)

        logger = logging.getLogger("d2rs_logger")
        logger.setLevel(level)
        logger.addHandler(handler)

        Log._logger = logger

    @staticmethod
    def debug(msg, data=[]):
        Log._log(logging.DEBUG, msg, data)

    @staticmethod
    def info(msg, data=[]):
        Log._log(logging.INFO, msg, data)

    @staticmethod
    def warn(msg, data=[]):
        Log._log(logging.WARNING, msg, data)

    @staticmethod
    def error(msg, data=[]):
        Log._log(logging.ERROR, msg, data)

    @staticmethod
    def crit(msg, data=[]):
        Log._log(logging.CRITICAL, msg, data)

    @staticmethod
    def _log(level, msg, data=[]):
        if Log._logger is None:
            return

        formatted = msg
        if len(data) > 0:
            formatted += Log._format_kvps(data)

        Log._logger.log(level, formatted)

    @staticmethod
    def _format_kvps(kvps):
        return f" {{ {', '.join([Log._format_kvp(kvp) for kvp in kvps])} }}"

    @staticmethod
    def _format_kvp(kvp):
        if isinstance(kvp[1], str):
            return f'{kvp[0]} = "{kvp[1]}"'
        else:
            return "{} = {}".format(kvp[0], kvp[1])
