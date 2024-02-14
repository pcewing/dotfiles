#!/usr/bin/env python

import json
import urllib.request

from .util import download_file, sh
from .log import Log

from enum import Enum
from typing import Tuple


class CompressionType(Enum):
    NONE = 1
    GZIP = 2
    XZ = 3


class ArchiveType(Enum):
    UNKNOWN = 1
    TAR = 2


class Archive:
    @staticmethod
    def extract(path: str, dst_dir: str, dry_run: bool) -> None:
        archive_type, compression_type = Archive._infer_type_from_name(path)

        extraction_funcs = {
            ArchiveType.TAR: Archive._extract_tar,
        }

        extraction_funcs[archive_type](path, compression_type, dst_dir, dry_run)

    def _extract_tar(path: str, compression_type: CompressionType, dst_dir: str, dry_run: bool) -> None:
        cmd = [ "tar", "--extract" ]

        if compression_type == CompressionType.GZIP:
            cmd.append("--gzip")
        elif compression_type == CompressionType.XZ:
            cmd.append("--xz")

        cmd += [
            "--file", path,
            "--directory", dst_dir,
        ]

        if dry_run:
            Log.info("Skipping archive extraction due to --dry-run")
        else:
            sh(cmd)

    @staticmethod
    def _infer_type_from_name(name: str) -> Tuple[ArchiveType, CompressionType]:
        if name.lower().endswith(".tar.gz"):
            return ArchiveType.TAR, CompressionType.GZIP
        elif name.lower().endswith(".txz"):
            return ArchiveType.TAR, CompressionType.XZ
        else:
            raise Exception("Failed to infer archive file type")
