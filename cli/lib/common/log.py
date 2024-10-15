#!/usr/bin/env python

import logging
import sys
from logging import LogRecord
from typing import Any, Optional, Union

LogLevel = int
LogHandler = Union[logging.StreamHandler, logging.FileHandler]
LogHandlers = list[LogHandler]

LogData = dict[str, Any]
LogDataKvp = tuple[str, Any]

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


def is_string_list(var: Any) -> bool:
    return isinstance(var, list) and all(isinstance(item, str) for item in var)


def _log_level_abbrev(level: int) -> str:
    if level not in _LOG_LEVEL_ABBREVIATIONS:
        raise Exception("Invalid log level '{}'".format(level))
    return _LOG_LEVEL_ABBREVIATIONS[level]


class Formatter(logging.Formatter):
    def formatTime(self, record: LogRecord, datefmt: Optional[str] = None) -> str:
        time = super(Formatter, self).formatTime(record, datefmt)
        return time.replace(",", ".")[11:]

    def format(self, record: LogRecord) -> str:
        level_abbrev = _log_level_abbrev(record.levelno)
        record.level_abbrev = level_abbrev
        return super(Formatter, self).format(record)


# Lightweight structured logging wrapper around Python's standard logging
# facilities. No effort has been made to optimize performance.
class Log:
    _logger = None

    @staticmethod
    def parse_level(level_str: str) -> LogLevel:
        key = level_str.lower()
        if key not in _LOG_LEVEL_STRINGS:
            raise Exception("Invalid log level '{}'".format(key))
        return _LOG_LEVEL_STRINGS[key]

    @staticmethod
    def init(
        name: str, level: LogLevel, stdout: bool = True, file: Optional[str] = None
    ) -> None:
        handlers: LogHandlers = []
        if stdout:
            handlers.append(logging.StreamHandler(sys.stdout))
        if file is not None:
            handlers.append(logging.FileHandler(file, mode="a"))

        if len(handlers) <= 0:
            return

        formatter = Formatter("%(level_abbrev)s %(asctime)s %(message)s")

        logger = logging.getLogger(name)
        logger.setLevel(level)

        for handler in handlers:
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        Log._logger = logger

    @staticmethod
    def debug(msg: str, data: LogData = {}) -> None:
        Log._log(logging.DEBUG, msg, data)

    @staticmethod
    def info(msg: str, data: LogData = {}) -> None:
        Log._log(logging.INFO, msg, data)

    @staticmethod
    def warn(msg: str, data: LogData = {}) -> None:
        Log._log(logging.WARNING, msg, data)

    @staticmethod
    def error(msg: str, data: LogData = {}) -> None:
        Log._log(logging.ERROR, msg, data)

    @staticmethod
    def fatal(msg: str, data: LogData = {}) -> None:
        Log._log(logging.FATAL, msg, data)

    @staticmethod
    def _log(level: LogLevel, msg: str, data: LogData = {}) -> None:
        if Log._logger is None:
            return
        Log._logger.log(level, Log._format_msg(msg, data))

    @staticmethod
    def _format_msg(msg: str, data: LogData) -> str:
        return msg + Log._format_data(data)

    @staticmethod
    def _format_data(data: LogData) -> str:
        if len(data) == 0:
            return ""
        return f" {{ {', '.join([Log._format_kvp(kvp) for kvp in data.items()])} }}"

    @staticmethod
    def _format_kvp(kvp: LogDataKvp) -> str:
        if isinstance(kvp[1], str):
            return f'{kvp[0]} = "{kvp[1]}"'
        elif is_string_list(kvp[1]):
            return kvp[0] + " = [" + ", ".join(kvp[1]) + "]"
        else:
            return "{} = {}".format(kvp[0], kvp[1])
