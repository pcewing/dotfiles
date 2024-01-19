#!/usr/bin/env python

import logging
import sys


# fmt: off
_LOG_LEVEL_STRINGS = {
    "debug":    logging.DEBUG,
    "info":     logging.INFO,
    "warn":     logging.WARN,
    "error":    logging.ERROR,
    "fatal":    logging.FATAL,
}

_LOG_LEVEL_ABBREVIATIONS = {
    logging.DEBUG:      "D",
    logging.INFO:       "I",
    logging.WARNING:    "W",
    logging.ERROR:      "E",
    logging.FATAL:      "F",
}
# fmt: on


def _log_level_from_str(log_level_str: str) -> int:
    key = log_level_str.lower()
    if key not in _LOG_LEVEL_STRINGS:
        raise Exception("Invalid log level '{}'".format(key))
    return _LOG_LEVEL_STRINGS[key]


def _log_level_abbrev(level: int) -> str:
    if level not in _LOG_LEVEL_ABBREVIATIONS:
        raise Exception("Invalid log level '{}'".format(level))
    return _LOG_LEVEL_ABBREVIATIONS[level]


class Formatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        time = super(Formatter, self).formatTime(record, datefmt)
        return time.replace(",", ".")[11:]

    def format(self, record):
        level_abbrev = _log_level_abbrev(record.levelno)
        record.level_abbrev = level_abbrev
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

        formatter = Formatter("%(level_abbrev)s %(asctime)s %(message)s")

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
    def fatal(msg, data=[]):
        Log._log(logging.FATAL, msg, data)

    @staticmethod
    def _log(level, msg, data=[]):
        if Log._logger is None:
            return
        Log._logger.log(level, Log._format_msg(msg, data))

    @staticmethod
    def _format_msg(msg, data):
        return msg + Log._format_kvps(data)

    @staticmethod
    def _format_kvps(kvps):
        if len(kvps) == 0:
            return ""
        return f" {{ {', '.join([Log._format_kvp(kvp) for kvp in kvps])} }}"

    @staticmethod
    def _format_kvp(kvp):
        if isinstance(kvp[1], str):
            return f'{kvp[0]} = "{kvp[1]}"'
        else:
            return "{} = {}".format(kvp[0], kvp[1])
