#!/usr/bin/env python

from __future__ import annotations

import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional

from lib.common.log import Log

# Prefer a real JSON5 parser if available. We'll fall back to strict JSON.
try:
    import json5 as _json_reader  # type: ignore
except Exception:
    _json_reader = None

import json as _json_fallback


class VersionCache:
    """
    A small TTL-based cache for "latest version" lookups.

    File schema (JSON5-compatible):
    {
      versions: {
        foo: {
          version: "v1.2.3",
          source: "github:owner/repo",
          update_time: "2025-12-14T17:42:10Z",
          last_attempt: "2025-12-14T17:42:10Z",
          last_error: "optional string",
        },
        ...
      }
    }
    """

    CACHE_PATH = Path("./version_cache.json5")
    MAX_AGE_DAYS = 7
    ENABLED = True

    @staticmethod
    def init(
        enabled: bool,
        cache_path: Path,
        max_age_days: int,
    ) -> None:
        VersionCache.ENABLED = enabled
        VersionCache.CACHE_PATH = cache_path
        VersionCache.MAX_AGE_DAYS = max_age_days

    @staticmethod
    def get_version(
        name: str,
        *,
        use_stale_on_failed_attempt: bool = True,
        failure_cooldown_seconds: Optional[int] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Returns the cached entry for `name`, or None if not present / not usable.

        Cache freshness is controlled by VersionCache.MAX_AGE_DAYS:
          - MAX_AGE_DAYS > 0 : entry must be newer than that many days
          - MAX_AGE_DAYS <= 0: freshness check disabled; always accept cached entry

        Negative caching behavior:
          - If the entry is stale (or missing) and there's evidence of a more recent
            failed attempt (last_attempt > update_time), then (optionally) return the
            cached entry anyway and print a warning, instead of treating it as a miss.
          - If failure_cooldown_seconds is set, the "failed attempt" shortcut only
            applies when last_attempt is within that cooldown window from now.
        """
        if not VersionCache.ENABLED:
            return None

        data = VersionCache._load()
        versions = data.get("versions", {})
        if not isinstance(versions, dict):
            # Corrupt schema; treat as empty.
            return None

        entry = versions.get(name)
        if not isinstance(entry, dict):
            return None

        # If TTL is disabled, return entry immediately
        max_age_days = getattr(VersionCache, "MAX_AGE_DAYS", None)
        if max_age_days is None or max_age_days <= 0:
            return entry

        max_age_seconds = max_age_days * 24 * 60 * 60

        now = VersionCache._utc_now()
        update_dt = VersionCache._parse_iso_utc(entry.get("update_time"))

        if update_dt is not None:
            age = (now - update_dt).total_seconds()
            if age <= max_age_seconds:
                return entry

        # Entry is stale (or missing update_time). Consider negative caching.
        if use_stale_on_failed_attempt:
            last_attempt_dt = VersionCache._parse_iso_utc(entry.get("last_attempt"))
            if last_attempt_dt is not None:
                # Failed attempt after last successful update?
                failed_after_update = (
                    update_dt is None or last_attempt_dt > update_dt
                )

                within_cooldown = True
                if failure_cooldown_seconds is not None:
                    within_cooldown = (
                        (now - last_attempt_dt).total_seconds()
                        <= failure_cooldown_seconds
                    )

                if failed_after_update and within_cooldown:
                    last_err = entry.get("last_error")
                    msg = (
                        f"[VersionCache] Using stale cached version for '{name}' "
                        f"because a recent fetch attempt failed."
                    )
                    if last_err:
                        msg += f" Last error: {last_err}"
                    Log.warn(msg)
                    return entry

        return None

    @staticmethod
    def update_version(name: str, version: str, source: Optional[str] = None) -> Dict[str, Any]:
        """
        Upserts a successful version lookup.
        - Sets update_time to now (UTC ISO8601, Z).
        - Also sets last_attempt to now (since we just attempted).
        - Clears last_error.
        Returns the updated entry.
        """
        data = VersionCache._load()
        versions = data.setdefault("versions", {})
        if not isinstance(versions, dict):
            data["versions"] = {}
            versions = data["versions"]

        now_iso = VersionCache._utc_now_iso()

        entry = versions.get(name)
        if not isinstance(entry, dict):
            entry = {}
            versions[name] = entry

        entry["version"] = version
        if source is not None:
            entry["source"] = source
        entry["update_time"] = now_iso
        entry["last_attempt"] = now_iso
        entry.pop("last_error", None)

        VersionCache._save(data)
        return entry

    @staticmethod
    def add_failed_attempt(name: str, error: Optional[str] = None, source: Optional[str] = None) -> Dict[str, Any]:
        """
        Records a failed attempt to refresh a version.
        - Sets last_attempt to now (UTC ISO8601, Z).
        - Stores last_error (if provided).
        - Optionally updates source.
        Does NOT modify update_time/version.
        Returns the updated entry.
        """
        data = VersionCache._load()
        versions = data.setdefault("versions", {})
        if not isinstance(versions, dict):
            data["versions"] = {}
            versions = data["versions"]

        now_iso = VersionCache._utc_now_iso()

        entry = versions.get(name)
        if not isinstance(entry, dict):
            entry = {}
            versions[name] = entry

        if source is not None:
            entry["source"] = source
        entry["last_attempt"] = now_iso
        if error is not None:
            entry["last_error"] = error

        VersionCache._save(data)
        return entry

    # -----------------------------
    # Internal helpers
    # -----------------------------

    @staticmethod
    def _utc_now() -> datetime:
        return datetime.now(timezone.utc)

    @staticmethod
    def _utc_now_iso() -> str:
        # Use second precision, Z suffix.
        return VersionCache._utc_now().replace(microsecond=0).isoformat().replace("+00:00", "Z")

    @staticmethod
    def _parse_iso_utc(value: Any) -> Optional[datetime]:
        if not isinstance(value, str) or not value:
            return None
        try:
            s = value.strip()
            # Accept "...Z" and "+00:00"
            if s.endswith("Z"):
                s = s[:-1] + "+00:00"
            dt = datetime.fromisoformat(s)
            if dt.tzinfo is None:
                # Assume UTC if timezone omitted (best-effort)
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(timezone.utc)
        except Exception:
            return None

    @staticmethod
    def _load() -> Dict[str, Any]:
        path = VersionCache.CACHE_PATH
        if not path.exists():
            return {"versions": {}}

        text = path.read_text(encoding="utf-8")

        # Try JSON5 if available; else fall back to strict JSON.
        if _json_reader is not None:
            try:
                data = _json_reader.loads(text)
                if isinstance(data, dict):
                    data.setdefault("versions", {})
                    return data
            except Exception:
                pass

        # Strict JSON fallback (will fail if you truly use JSON5 features like comments/trailing commas)
        try:
            data = _json_fallback.loads(text)
            if isinstance(data, dict):
                data.setdefault("versions", {})
                return data
        except Exception:
            # If unreadable, don't clobber the file automatically; just act like empty.
            Log.warn(f"[VersionCache] failed to parse cache file: {path}")
            return {"versions": {}}

        return {"versions": {}}

    @staticmethod
    def _save(data: Dict[str, Any]) -> None:
        path = VersionCache.CACHE_PATH
        path.parent.mkdir(parents=True, exist_ok=True)

        # Write JSON that is also valid JSON5 (quotes, etc.). Pretty for humans.
        serialized = _json_fallback.dumps(data, indent=2, sort_keys=True) + "\n"

        # Atomic write: temp file in same directory, then replace.
        tmp_fd = None
        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w",
                encoding="utf-8",
                dir=str(path.parent),
                delete=False,
                prefix=path.name + ".tmp.",
            ) as f:
                tmp_fd = f.fileno()
                tmp_path = f.name
                f.write(serialized)
                f.flush()
                os.fsync(tmp_fd)

            os.replace(tmp_path, path)
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass
