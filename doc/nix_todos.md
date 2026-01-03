# Nix Migration TODOs

This document tracks remaining work to achieve full parity between the old provisioning systems (shell scripts in `provision/` and Python scripts in `cli/lib/provision/`) and the new Nix/Home Manager configuration.

## Status Legend
- [ ] Not started
- [~] Partial / In progress
- [x] Complete

---

## 1. Missing Packages

### 1.1 Core Utilities

| Package | Old Location | Status | Notes |
|---------|--------------|--------|-------|
| `curl` | apt (shell) | [ ] | Basic utility, should be in core.nix |
| `vim` | apt (shell) | [ ] | Standalone vim as backup (nvim is primary) |
| `libfuse2` | apt (shell) | [ ] | Required for AppImage support |
| `dos2unix` | apt (Python) | [ ] | Line ending converter |
| `apt-file` | apt (shell) | [ ] | May not be needed with Nix |
| `software-properties-common` | apt (shell) | [ ] | Ubuntu-specific, not needed for Nix |

### 1.2 Desktop/GUI Utilities

| Package | Old Location | Status | Notes |
|---------|--------------|--------|-------|
| `kitty` | Custom install (shell/Python) | [ ] | Terminal emulator - add to desktop.nix |
| `usb-creator-gtk` | apt (shell) | [ ] | USB flash tool - add to desktop.nix if needed |
| `kitty-terminfo` | apt (shell) | [ ] | May come with kitty package |

### 1.3 Development Tools

| Package | Old Location | Status | Notes |
|---------|--------------|--------|-------|
| `clang` | apt (shell) | [ ] | C/C++ compiler (clang-tools provides clangd but not the compiler) |
| `build-essential` equivalent | apt (shell) | [~] | `gcc` is present; may need `binutils`, `libc-dev`, etc. |
| `tree-sitter` CLI | Python provisioner | [ ] | Standalone CLI, separate from nvim-treesitter plugin |
| `ninja` | implicit in old | [ ] | Build system (used for building i3) |

---

## 2. System Configuration

### 2.1 Display Manager Integration

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Install `xsession.desktop` | shell script | [ ] | Copies to `/usr/share/xsessions/xsession.desktop` |
| Install `sway-user.desktop` | shell script | [ ] | Copies to `/usr/share/wayland-sessions/sway-user.desktop` |

**Note:** These require root access to install into system directories. Options:
1. Use NixOS with display manager configuration
2. Keep as a manual post-install step
3. Create a separate bootstrap script for system-level config

### 2.2 Editor Alternatives

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| `update-alternatives` for `vi` | shell/Python | [ ] | Points to nvim |
| `update-alternatives` for `vim` | shell/Python | [ ] | Points to nvim |
| `update-alternatives` for `editor` | shell/Python | [ ] | Points to nvim |

**Note:** Nix handles this differently via `programs.neovim.defaultEditor = true` and shell aliases. May not be necessary if all shells source the Nix profile.

### 2.3 MPD Service Management

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Disable system mpd.service | shell script | [ ] | `systemctl disable/mask mpd.service` |
| Disable system mpd.socket | shell script | [ ] | `systemctl disable/mask mpd.socket` |
| Disable user mpd.service | shell script | [ ] | `systemctl --user disable/mask mpd.service` |
| Disable user mpd.socket | shell script | [ ] | `systemctl --user disable/mask mpd.socket` |

**Note:** Home Manager can manage user systemd units. Consider using `home-manager` services.mpd if running mpd as a user service, or document manual steps.

---

## 3. Docker Configuration

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Install Docker packages | Python provisioner | [ ] | containerd, docker-ce, docker-cli, buildx, compose |
| Add user to docker group | Python provisioner | [ ] | Requires system-level config |
| Configure Docker daemon | - | [ ] | Optional: daemon.json settings |

**Note:** Docker installation with Nix can be tricky on non-NixOS. Options:
1. Use the existing Python/shell provisioner for Docker
2. Install Docker via system package manager
3. Use rootless Docker or Podman

There's a `nix/home/features/development.nix` that could include Docker config if using NixOS.

---

## 4. WSL-Specific Configuration

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Install `win32yank` | Python provisioner | [ ] | Already has TODO in wsl.nix |
| Configure clipboard integration | Python provisioner | [ ] | win32yank for nvim clipboard |

**Implementation suggestion for wsl.nix:**
```nix
home.packages = with pkgs; [
  win32yank
];
```

---

## 5. Custom/Third-Party Tools

### 5.1 wpr Tool

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Install `wpr` | shell script | [ ] | Custom tool from S3: `pcewing-wpr` |

**Note:** This appears to be a personal tool. Options:
1. Create a Nix derivation that fetches from S3
2. Keep as manual installation
3. Add to a local overlay

### 5.2 Default Terminal Emulator

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Set kitty as x-terminal-emulator | shell script | [ ] | Uses `update-alternatives` |

---

## 6. i3/Window Manager

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| Verify i3 gaps support | shell/Python | [ ] | Old scripts built i3-gaps from source |
| Install i3status | apt (shell) | [ ] | Should verify this is included |
| py3status | pip (Python) | [x] | In desktop.nix Python packages |

**Note:** As of i3 version 4.22, gaps support was merged into mainline i3. The Nix `i3` package should include this. Verify the version in nixpkgs matches or exceeds 4.22.

---

## 7. Neovim Ecosystem

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| pynvim | pip (shell/Python) | [x] | In core.nix Python packages |
| nvim-treesitter grammars | Python provisioner | [x] | Using `withAllGrammars` in core.nix |
| markdown.nvim plugin | core.nix TODO | [ ] | Commented out due to package issues |
| cql-vim plugin | core.nix TODO | [ ] | Cassandra CQL support |
| mesonic plugin | core.nix TODO | [ ] | Meson build system integration |

---

## 8. Python Environment

| Package | Old Location | Status | Notes |
|---------|--------------|--------|-------|
| black | pip (Python) | [x] | In core.nix |
| mypy | pip (Python) | [x] | In core.nix |
| isort | pip (Python) | [x] | In core.nix |
| flake8 | pip (Python) | [x] | In core.nix |
| autoflake | pip (Python) | [x] | In core.nix |
| ruff | pip (Python) | [x] | In core.nix (as system package) |
| argcomplete | pip (Python) | [x] | In core.nix |
| json5 | pip (Python) | [x] | In core.nix |
| python-mpd2 | pip (shell) | [x] | In core.nix as `mpd2` |
| py3status | pip (Python) | [x] | In desktop.nix |

---

## 9. Manjaro/Arch-Specific (Low Priority)

The `provision/manjaro.sh` script includes some packages not in the Ubuntu scripts:

| Package | Status | Notes |
|---------|--------|-------|
| `discord` | [ ] | Chat application |
| `firefox` | [ ] | Browser (may want to add) |
| `flatpak` | [ ] | Universal package manager |
| `kicad` | [ ] | PCB design software |
| `poppler` | [ ] | PDF utilities |
| `transmission-gtk` | [ ] | BitTorrent client |
| `sway` ecosystem | [ ] | Wayland compositor (mako, swaybg, swayidle, swaylock, waybar) |

---

## 10. Configuration Files / Dotfiles Links

| Task | Status | Notes |
|------|--------|-------|
| All links from links.json | [x] | Implemented in `dotfiles-links.nix` |
| Verify parity with links.json | [x] | Both files appear identical |

---

## 11. Activation Scripts / Post-Install

| Task | Old Location | Status | Notes |
|------|--------------|--------|-------|
| dot CLI completion | Python provisioner | [x] | Implemented in core.nix activation |
| MPD directories creation | shell script | [x] | Implemented in desktop.nix activation |
| flavours update | shell/Python | [ ] | May need activation script to run `flavours update all` |

---

## Priority Recommendations

### High Priority (Functionality Gaps)
1. Add `kitty` to desktop.nix
2. Add `curl` to core.nix
3. Implement win32yank in wsl.nix
4. Verify i3 gaps support works with Nix package

### Medium Priority (Developer Experience)
5. Add `tree-sitter` CLI
6. Add `clang` compiler (not just clang-tools)
7. Add full build toolchain (binutils, etc.)
8. Add `libfuse2` for AppImage support

### Low Priority (Nice to Have)
9. Document display manager desktop file installation
10. Document/implement Docker setup
11. Add wpr tool installation
12. Add remaining Manjaro packages if needed

### Potentially Obsolete
- `apt-file`, `software-properties-common` - Ubuntu/apt-specific
- Building i3-gaps from source - now in mainline i3
- `youtube-dl` - replaced by `yt-dlp` which is already included

---

## Notes

### Home Manager vs NixOS

Some items (display manager config, system services, docker group) are better handled by NixOS than Home Manager. If running on a non-NixOS system, these will need:
- Manual installation steps
- A separate bootstrap script
- System-level Nix configuration

### Version Pinning

The old provisioners had version caching and would install specific versions. Nix handles this via the flake lock file, but be aware that:
- nixpkgs version determines package versions
- Consider using overlays for packages that need specific versions
- The flake.lock should be committed to ensure reproducibility
