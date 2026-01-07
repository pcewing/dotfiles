{ pkgs, lib, ... }:

let
    win32yankVersion = "v0.1.1";
    win32yankUrl = "https://github.com/equalsraf/win32yank/releases/download/${win32yankVersion}/win32yank-x64.zip";
    win32yankInstallDir = "/mnt/c/bin";
    win32yankExe = "${win32yankInstallDir}/win32yank.exe";
    win32yankVersionFile = "${win32yankInstallDir}/win32yank_version.txt";
in
{
    home.sessionVariables = {
        BROWSER = "wslview";
    };

    # Install win32yank for better clipboard integration. It more gracefully
    # handles inconsistencies with line endings when copying and pasting
    # between Windows and WSL.
    # There's an open issue as of implementing this on 2024-05-20 where
    # running win32yank.exe from path within the WSL file system is very slow:
    # https://github.com/equalsraf/win32yank/issues/22
    # To avoid that, make sure we install this on the Windows file system in `C:\bin`.
    home.activation.installWin32yank = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        WIN32YANK_VERSION="${win32yankVersion}"
        WIN32YANK_URL="${win32yankUrl}"
        WIN32YANK_DIR="${win32yankInstallDir}"
        WIN32YANK_EXE="${win32yankExe}"
        WIN32YANK_VERSION_FILE="${win32yankVersionFile}"

        install_win32yank() {
          echo "Installing win32yank $WIN32YANK_VERSION..."
          mkdir -p "$WIN32YANK_DIR"
          TMP_DIR=$(mktemp -d)
          ${pkgs.curl}/bin/curl -sL "$WIN32YANK_URL" -o "$TMP_DIR/win32yank.zip"
          ${pkgs.unzip}/bin/unzip -o "$TMP_DIR/win32yank.zip" -d "$TMP_DIR"
          cp "$TMP_DIR/win32yank.exe" "$WIN32YANK_EXE"
          chmod +x "$WIN32YANK_EXE"
          echo "$WIN32YANK_VERSION" > "$WIN32YANK_VERSION_FILE"
          rm -rf "$TMP_DIR"
          echo "win32yank $WIN32YANK_VERSION installed to $WIN32YANK_EXE"
        }

        # Check if we need to install or update
        if [ ! -f "$WIN32YANK_EXE" ]; then
          echo "win32yank not found, installing..."
          install_win32yank
        elif [ ! -f "$WIN32YANK_VERSION_FILE" ]; then
          echo "win32yank version file not found, reinstalling..."
          install_win32yank
        elif [ "$(cat "$WIN32YANK_VERSION_FILE")" != "$WIN32YANK_VERSION" ]; then
          echo "win32yank version mismatch (have $(cat "$WIN32YANK_VERSION_FILE"), want $WIN32YANK_VERSION), updating..."
          install_win32yank
        else
          echo "win32yank $WIN32YANK_VERSION already installed"
        fi
    '';

    # Link the wslrc file. This is only active for WSL hosts.
    home.file.".wslrc".source = ../../../config/wslrc;

    # Download wezterm shell integration script
    home.activation.downloadWeztermShellIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        WEZTERM_SH_URL="https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh"
        WEZTERM_SH_DEST="$HOME/wezterm.sh"

        if [ ! -f "$WEZTERM_SH_DEST" ]; then
          echo "Downloading wezterm.sh for shell integration..."
          ${pkgs.curl}/bin/curl -sfL "$WEZTERM_SH_URL" -o "$WEZTERM_SH_DEST"
          chmod +x "$WEZTERM_SH_DEST"
          echo "wezterm.sh installed to $WEZTERM_SH_DEST"
        else
          echo "wezterm.sh already exists, skipping download."
        fi
    '';
}
