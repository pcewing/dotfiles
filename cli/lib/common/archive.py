#!/usr/bin/env python


from enum import Enum
from typing import Tuple

from lib.common.log import Log
from lib.common.util import sh


class CompressionType(Enum):
    NONE = 1
    GZIP = 2
    XZ = 3


class ArchiveType(Enum):
    UNKNOWN = 1
    TAR = 2
    NONE = 3
    ZIP = 4


class Archive:
    @staticmethod
    def extract(path: str, dst_dir: str, dry_run: bool) -> None:
        archive_type, compression_type = Archive._infer_type_from_name(path)

        extraction_funcs = {
            ArchiveType.TAR: Archive._extract_tar,
            ArchiveType.NONE: Archive._decompress,
            ArchiveType.ZIP: Archive._unzip,
        }

        extraction_funcs[archive_type](path, compression_type, dst_dir, dry_run)

    def _extract_tar(
        path: str, compression_type: CompressionType, dst_dir: str, dry_run: bool
    ) -> None:
        cmd = ["tar", "--extract"]

        if compression_type == CompressionType.GZIP:
            cmd.append("--gzip")
        elif compression_type == CompressionType.XZ:
            cmd.append("--xz")

        cmd += [
            "--file",
            path,
            "--directory",
            dst_dir,
        ]

        if dry_run:
            Log.info("skipping archive extraction due to --dry-run")
        else:
            sh(cmd)

    def _unzip(
        path: str, compression_type: CompressionType, dst_dir: str, dry_run: bool
    ) -> None:
        Log.info("unzipping archive", {"path": path, "dst_dir": dst_dir})

        cmd = ["unzip", "-o", path, "-d", dst_dir]

        # Compression type is currently ignored for zip files

        if dry_run:
            Log.info("skipping zip file extraction", {"reason": "dry run"})
        else:
            sh(cmd)

    def _decompress(
        path, compression_type: CompressionType, dst_dir: str, dry_run: bool
    ) -> None:
        cmd = []
        if compression_type == CompressionType.GZIP:
            cmd.append("gunzip")

        cmd += [
            "--file",
            path,
            "--directory",
            dst_dir,
        ]

        if dry_run:
            Log.info("skipping archive extraction due to --dry-run")
        else:
            sh(cmd)

    @staticmethod
    def _infer_type_from_name(name: str) -> Tuple[ArchiveType, CompressionType]:
        if name.lower().endswith(".tar.gz"):
            return ArchiveType.TAR, CompressionType.GZIP
        elif name.lower().endswith(".gz"):
            return ArchiveType.NONE, CompressionType.GZIP
        elif name.lower().endswith(".tar.xz"):
            return ArchiveType.TAR, CompressionType.XZ
        elif name.lower().endswith(".txz"):
            return ArchiveType.TAR, CompressionType.XZ
        elif name.lower().endswith(".zip"):
            return ArchiveType.ZIP, CompressionType.NONE
        else:
            raise Exception("Failed to infer archive file type")
