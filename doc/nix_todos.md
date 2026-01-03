# Nix Migration TODOs

This document tracks remaining work to achieve full parity between the old provisioning systems (shell scripts in `provision/` and Python scripts in `cli/lib/provision/`) and the new Nix/Home Manager configuration.

**Important:** The primary entry point is `apply.sh`, which handles bootstrap/system-level tasks before invoking Home Manager. Many items that cannot or should not be managed by Nix are intentionally handled there.

## Status Legend
- [ ] Not started
- [~] Partial / In progress
- [x] Complete

---

## 1. Handled by apply.sh (Intentionally Not in Nix)

These items are managed by `apply.sh` rather than Nix, typically because they require root access, have OpenGL/driver issues with Nix, or are needed before Nix is available.

### 1.1 APT Bootstrap Packages

Installed via apt before Nix is available or to avoid Nix packaging issues:

| Package | Reason | Notes |
|---------|--------|-------|
| `apt-file` | Pre-Nix bootstrap | Ubuntu package search |
| `ca-certificates` | Pre-Nix bootstrap | Required for HTTPS/curl |
| `curl` | Pre-Nix bootstrap | Needed to install Nix itself |
| `git` | Pre-Nix bootstrap | Needed to clone dotfiles |
| `jq` | Pre-Nix bootstrap | Used by apply.sh to parse hosts.json |
| `libfuse` | Pre-Nix bootstrap | AppImage support |
| `locate` | Pre-Nix bootstrap | File search |
| `software-properties-common` | Pre-Nix bootstrap | Ubuntu apt tooling |
| `xz-utils` | Pre-Nix bootstrap | Compression utilities |

### 1.2 Desktop Packages (OpenGL Issues)

These are installed via apt to avoid OpenGL/graphics driver issues that are common with Nix on non-NixOS systems:

| Package | Reason | Notes |
|---------|--------|-------|
| `i3` | OpenGL/driver issues | Window manager |
| `i3status` | Companion to i3 | Status bar |
| `kitty` | OpenGL/driver issues | GPU-accelerated terminal |

### 1.3 System-Level Configuration

These require root access and modify system directories:

| Task | Location in apply.sh | Notes |
|------|---------------------|-------|
| `update-alternatives` for vi/vim/editor | `set_default_terminal_and_editor()` | Points to nvim |
| `update-alternatives` for x-terminal-emulator | `set_default_terminal_and_editor()` | Points to kitty (desktop only) |
| Install `xsession.desktop` | `install_session_desktop_files()` | To `/usr/share/xsessions/` |
| Install `sway-user.desktop` | `install_session_desktop_files()` | To `/usr/share/wayland-sessions/` |

### 1.4 Docker Installation

| Task | Location in apply.sh | Notes |
|------|---------------------|-------|
| Install Docker packages | `install_docker()` | docker-ce, containerd, buildx, compose |
| Add user to docker group | `install_docker()` | Requires logout/reboot to take effect |

### 1.5 Nix Bootstrap

| Task | Location in apply.sh | Notes |
|------|---------------------|-------|
| Install Nix | `install_nix_if_needed()` | Single-user installation |
| Enable flakes | `enable_nix_experimental()` | Writes to ~/.config/nix/nix.conf |
| Apply Home Manager | `apply_home_manager()` | Runs `home-manager switch` |

---

## 2. Remaining TODOs

### 2.1 Neovim Plugins (Nix Package Issues)

| Plugin | Priority | Notes |
|--------|----------|-------|
| markdown.nvim | Low | Commented out in core.nix due to package issues |
| cql-vim | Low | Cassandra CQL support |
| mesonic | Low | Meson build system integration |

---

## 3. Already Complete

### 3.1 Packages in Nix

| Category | Packages |
|----------|----------|
| Core utilities | wget, gnupg, jq, plocate, fzf, nettools, unzip, libuchardet, xz, dos2unix |
| CLI tools | gnumake, gcc, cmake, htop, iotop, universal-ctags, ranger, tmux, neofetch, id3v2, calcurse, vim, tree-sitter |
| Search/utils | ripgrep |
| Theming | flavours |
| C/C++ | clang-tools (clangd) |
| Desktop/GUI | font-awesome, rofi, dunst, feh, sxiv, nitrogen, pavucontrol, picom, scrot, gucharmap, keepassxc, remmina, i3lock, meld, xclip, wl-clipboard, xdotool, libwebp, arandr, rxvt-unicode, ventoy |
| Media | inkscape, mpv, vlc, easytag, blueman, mpd, ncmpcpp, cava, yt-dlp |
| Gaming | steam, steam-run, runelite |
| Development | go, gopls, delve, rustup, nodejs, npm, openjdk, dotnet-sdk, meson, ninja |
| Proprietary | bcompare |
| Custom | wpr (via custom derivation in `nix/home/packages/wpr.nix`) |

### 3.2 Python Packages (via unified environment)

| Package | Location |
|---------|----------|
| pip, pynvim, mpd2, black, mypy, isort, flake8, autoflake, argcomplete, json5 | core.nix |
| py3status | desktop.nix |
| ruff | core.nix (system package) |

### 3.3 Neovim

- Installed via `programs.neovim` with plugins
- treesitter with all grammars via `withAllGrammars`
- LSP config, telescope, copilot, etc.

### 3.4 Dotfiles Links

All links from `links.json` are implemented in `dotfiles-links.nix`.

### 3.5 Activation Scripts

| Task | Location |
|------|----------|
| dot CLI completion | core.nix `home.activation.dotArgcomplete` |
| MPD directories creation | desktop.nix `home.activation.createMpdDirs` |
| flavours update | core.nix `home.activation.flavoursUpdate` |
| win32yank installation | wsl.nix `home.activation.installWin32yank` |

### 3.6 WSL-Specific

| Task | Location | Notes |
|------|----------|-------|
| win32yank | wsl.nix activation script | Downloads to `/mnt/c/bin/` on Windows filesystem |
| BROWSER env var | wsl.nix | Set to `wslview` |

---

## 4. Potentially Obsolete

Items from old provisioners that are no longer needed:

| Item | Reason |
|------|--------|
| Building i3-gaps from source | Gaps merged into mainline i3 as of 4.22 |
| `youtube-dl` | Replaced by `yt-dlp` (already in Nix) |
| `compton` | Replaced by `picom` (already in Nix) |
| Custom kitty installation | Now installed via apt in apply.sh |
| Custom neovim AppImage | Now installed via Nix |
| Custom flavours installation | Now installed via Nix |
| Custom ripgrep installation | Now installed via Nix |
| Custom nodejs installation | Now installed via Nix |
| `usb-creator-gtk` | Replaced by `ventoy` |

---

## 5. Manjaro/Arch-Specific (Low Priority)

The `provision/manjaro.sh` script includes packages not in the Ubuntu scripts. Consider adding if needed:

| Package | Notes |
|---------|-------|
| `discord` | Chat application |
| `firefox` | Browser |
| `flatpak` | Universal package manager |
| `kicad` | PCB design software |
| `poppler` | PDF utilities |
| `transmission-gtk` | BitTorrent client |
| `sway` ecosystem | mako, swaybg, swayidle, swaylock, waybar |

---

## 6. Future Considerations

### Moving More to Nix

Some items currently in apply.sh could potentially move to Nix in the future:

1. **kitty/i3**: If OpenGL issues are resolved or using NixOS
2. **Docker**: Could use Podman from Nix as alternative
3. **System alternatives**: Could rely solely on Nix profile PATH ordering

### NixOS Migration

If migrating to NixOS, many apply.sh tasks would move to system configuration:
- Display manager desktop files
- Docker installation and group management
- System-wide alternatives

### Version Pinning

The old provisioners had version caching. Nix handles this via flake.lock:
- Commit flake.lock for reproducibility
- Use `nix flake update` to update nixpkgs
- Consider overlays for packages needing specific versions

### Custom Packages

Custom packages are stored in `nix/home/packages/`:
- `wpr.nix` - Personal wpr tool fetched from S3

To add new custom packages:
1. Create a `.nix` file in `nix/home/packages/`
2. Use `pkgs.callPackage ../packages/yourpkg.nix { }` in the relevant role
3. Add to the packages list
