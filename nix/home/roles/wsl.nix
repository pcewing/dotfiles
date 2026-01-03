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

  # Install win32yank to Windows filesystem for clipboard integration
  # This needs to be on NTFS (not WSL filesystem) for performance reasons
  home.activation.installWin32yank =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

    # TODO: Link the file ../../../config/wslrc to ~/.wslrc
    # Probably don't use the dotfiles-links.nix file since we only want this on
    # WSL? Unless there's a good way to add it to the `items` array for WSL
    # only

    # TODO: Add an activation script to download this wezterm.sh file from github:
    # https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh
    # and put it at the path: "$HOME/wezterm.sh"
}
