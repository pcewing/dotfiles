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

## 2. Actual TODOs (Missing from Both Nix and apply.sh)

### 2.1 Missing Packages

| Package | Old Location | Priority | Notes |
|---------|--------------|----------|-------|
| `vim` | apt (shell) | Low | Standalone vim as backup (nvim is primary) |
| `dos2unix` | apt (Python) | Low | Line ending converter |
| `tree-sitter` CLI | Python provisioner | Medium | Standalone CLI, separate from nvim-treesitter plugin |
| `clang` | apt (shell) | Medium | C/C++ compiler (clang-tools provides clangd but not the compiler) |
| `ninja` | implicit in old | Low | Build system |
| `usb-creator-gtk` | apt (shell) | Low | USB flash tool |

### 2.2 WSL-Specific

| Task | Old Location | Priority | Notes |
|------|--------------|----------|-------|
| Install `win32yank` | Python provisioner | High | Already has TODO in wsl.nix |
| Configure clipboard integration | Python provisioner | High | win32yank for nvim clipboard |

**Implementation suggestion for wsl.nix:**
```nix
home.packages = with pkgs; [
  win32yank
];
```

### 2.3 MPD Service Management

| Task | Old Location | Priority | Notes |
|------|--------------|----------|-------|
| Disable system mpd.service | shell script | Low | `systemctl disable/mask mpd.service` |
| Disable system mpd.socket | shell script | Low | `systemctl disable/mask mpd.socket` |
| Disable user mpd.service | shell script | Low | `systemctl --user disable/mask mpd.service` |
| Disable user mpd.socket | shell script | Low | `systemctl --user disable/mask mpd.socket` |

**Note:** This was done in the old scripts to prevent the system mpd from conflicting with user-run mpd. May need to add to apply.sh or document as a manual step.

### 2.4 Custom Tools

| Task | Old Location | Priority | Notes |
|------|--------------|----------|-------|
| Install `wpr` | shell script | Low | Custom tool from S3: `pcewing-wpr` |

### 2.5 Neovim Plugins (Nix Package Issues)

| Plugin | Priority | Notes |
|--------|----------|-------|
| markdown.nvim | Low | Commented out in core.nix due to package issues |
| cql-vim | Low | Cassandra CQL support |
| mesonic | Low | Meson build system integration |

### 2.6 Activation Scripts

| Task | Old Location | Priority | Notes |
|------|--------------|----------|-------|
| `flavours update all` | shell/Python | Low | May need activation script after fresh install |

---

## 3. Already Complete

### 3.1 Packages in Nix

| Category | Packages |
|----------|----------|
| Core utilities | wget, gnupg, jq, plocate, fzf, nettools, unzip, libuchardet, xz |
| CLI tools | gnumake, gcc, cmake, meson, htop, iotop, universal-ctags, ranger, tmux, neofetch, id3v2, calcurse |
| Search/utils | ripgrep |
| Theming | flavours |
| C/C++ | clang-tools (clangd) |
| Desktop/GUI | font-awesome, rofi, dunst, feh, sxiv, nitrogen, pavucontrol, picom, scrot, gucharmap, keepassxc, remmina, i3lock, meld, xclip, wl-clipboard, xdotool, libwebp, arandr, rxvt-unicode |
| Media | inkscape, mpv, vlc, easytag, blueman, mpd, ncmpcpp, cava, yt-dlp |
| Gaming | steam, steam-run, runelite |
| Development | go, gopls, delve, rustup, nodejs, npm, openjdk, dotnet-sdk |
| Proprietary | bcompare |

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
| dot CLI completion | core.nix activation |
| MPD directories creation | desktop.nix activation |

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
