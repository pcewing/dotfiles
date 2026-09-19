#!/usr/bin/env python

import os
import shutil
import subprocess

from dot.lib.common.alternatives import Alternatives
from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags


class SystemConfigProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        self._set_editor_alternatives()
        self._link_fd()

        if not self._args.tags.has(Tags.x11):
            Log.info("x11 tag not present, skipping desktop system setup")
            return

        self._set_terminal_alternative()
        self._install_session_files()
        self._create_mpd_dirs()
        self._mask_mpd_services()
        self._generate_wallpaper()
        self._install_set_bg_script()

    def _set_editor_alternatives(self) -> None:
        nvim_path = shutil.which("nvim")
        if nvim_path is None:
            Log.warn("nvim not found on PATH; skipping editor alternatives")
            return

        for name in ("vi", "vim", "editor"):
            Alternatives.install(
                f"/usr/bin/{name}", name, nvim_path, 60, True, self._args.dry_run
            )
            Alternatives.set(name, nvim_path, True, self._args.dry_run)

    def _set_terminal_alternative(self) -> None:
        kitty_path = shutil.which("kitty")
        if kitty_path is None:
            Log.warn("kitty not found on PATH; skipping terminal alternative")
            return

        Alternatives.install(
            "/usr/bin/x-terminal-emulator",
            "x-terminal-emulator",
            kitty_path,
            50,
            True,
            self._args.dry_run,
        )
        Alternatives.set("x-terminal-emulator", kitty_path, True, self._args.dry_run)

    def _install_session_files(self) -> None:
        self._sudo_install(
            os.path.join(Dir.config(), "xsession.desktop"),
            "/usr/share/xsessions/xsession.desktop",
        )
        self._sudo_install(
            os.path.join(Dir.config(), "sway-user.desktop"),
            "/usr/share/wayland-sessions/sway-user.desktop",
        )

    def _sudo_install(self, src: str, dst: str) -> None:
        if not os.path.isfile(src):
            Log.warn("session file is missing, skipping", {"path": src})
            return

        Log.info("installing session file", {"src": src, "dst": dst})
        if self._args.dry_run:
            return

        if subprocess.call(["sudo", "install", "-m", "0644", src, dst]) != 0:
            raise Exception(f"Failed to install {dst}")

    def _create_mpd_dirs(self) -> None:
        dirs = [
            os.path.join(Dir.home(), ".mpd", "playlists"),
            os.path.join(Dir.home(), ".local", "share", "mpd"),
        ]
        for path in dirs:
            if self._args.dry_run:
                Log.info("would create directory", {"path": path})
            else:
                os.makedirs(path, exist_ok=True)

    def _mask_mpd_services(self) -> None:
        if shutil.which("systemctl") is None:
            return

        Log.info("stopping and masking the system mpd services")
        if self._args.dry_run:
            return

        commands = [
            ["sudo", "systemctl", "stop", "--now", "mpd.service", "mpd.socket"],
            ["sudo", "systemctl", "disable", "mpd.service", "mpd.socket"],
            ["sudo", "systemctl", "mask", "mpd.service", "mpd.socket"],
        ]
        # These are best effort; the units may not exist on every host.
        for cmd in commands:
            subprocess.call(cmd)

    def _generate_wallpaper(self) -> None:
        rsvg = shutil.which("rsvg-convert")
        if rsvg is None:
            Log.warn("rsvg-convert not found; skipping wallpaper generation")
            return

        src = os.path.join(Dir.dot(), "img", "wallpaper.svg")
        dst = os.path.join(Dir.home(), "Pictures", "default_wallpaper.png")

        if self._args.dry_run:
            Log.info("would generate wallpaper", {"src": src, "dst": dst})
            return

        os.makedirs(os.path.dirname(dst), exist_ok=True)
        cmd = [rsvg, "-w", "3840", "-h", "2160", "-o", dst, src]
        if subprocess.call(cmd) != 0:
            raise Exception("Failed to generate wallpaper")

    def _install_set_bg_script(self) -> None:
        src = os.path.join(Dir.dot(), "templates", "set-bg.sh")
        dst = os.path.join(Dir.home(), "set-bg.sh")

        if os.path.exists(dst) and not self._args.force:
            Log.info("set-bg.sh already exists; leaving it untouched", {"path": dst})
            return

        if self._args.dry_run:
            Log.info("would install set-bg.sh", {"src": src, "dst": dst})
            return

        shutil.copyfile(src, dst)
        os.chmod(dst, 0o755)

    def _link_fd(self) -> None:
        # Ubuntu's fd-find package installs the binary as `fdfind`, but
        # Neovim/Telescope expect `fd`.
        if shutil.which("fd") is not None:
            return

        fdfind = shutil.which("fdfind")
        if fdfind is None:
            return

        dst = os.path.join(Dir.home(), ".local", "bin", "fd")
        if self._args.dry_run:
            Log.info("would symlink fd", {"src": fdfind, "dst": dst})
            return

        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.islink(dst) or os.path.exists(dst):
            os.remove(dst)
        os.symlink(fdfind, dst)
