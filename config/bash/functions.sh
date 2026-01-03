#!/usr/bin/env bash

function yell() { >&2 echo "$*";  }

# Checks whether or not commands passed as parameters are installed. If a
# command that is not recognized is encountered, an error message is printed
# and the command returns 1 so that it can be used in conditional statements.
# Example:
# function foo() {
#     installed "git" "npm" || return 1
#     echo "Git and NPM are installed!"
# }
function installed() {
    arr=("$@")
    for cmd in "${arr[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            yell "ERROR: missing dependency: $cmd"
            return 1
        fi
    done
}

# Publish a desktop error notification
function error_notify() {
    local summary="$1"
    local message="$2"
    notify-send -u normal -t 5000 "$summary" "$message"
}

# Open graphical file manager in the current directory
function fm() {
    local path="$1"

    installed "xdg-mime" "gtk-launch" || return 1

    file_manager="$(xdg-mime query default inode/directory | sed -e 's/\.desktop//')"

    if test -z "path"; then
        path="."
    fi

    gtk-launch "$file_manager" "$path"
}

# Create an executable bash script and open it in Neovim
function nvims() {
    installed "nvim" || return 1

    local script_name
    script_name="$1"

    if [[ -z "$script_name" ]]; then
        echo "Usage: nvims <filename>" 1>&2
        return 1
    fi

    if [[ -e "$script_name" ]]; then
        echo "ERROR: File $script_name already exists" 1>&2
        return 1
    fi

    cat << 'EOF' > "$script_name"
#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

EOF

    chmod +x "$script_name"
    nvim "$script_name"
}

# Create an executable Python file and open it in NeoVim
function nvimp() {
    installed "nvim" || return 1

    local script_name
    script_name="$1"

    if [[ -z "$script_name" ]]; then
        echo "Usage: nvimp <filename>" 1>&2
        return 1
    fi

    if [[ -e "$script_name" ]]; then
        echo "ERROR: File $script_name already exists" 1>&2
        return 1
    fi

    cp "$DOTFILES/templates/nvimp.template.py" "$script_name"
    chmod +x "$script_name"
    nvim "$script_name"
}

# Download the audio from a YouTube video as an MP3 file
function yt_mp3() {
    installed "youtube-dl" || return 1

    youtube-dl -x --audio-format "mp3" "$1"
}

# WARNING: This shouldn't be called from an interactive shell as the passphrase
# will be written in plaintext to $HISTFILE. It is only implemented so that
# scripts can avoid asking for the passphrase multiple times when encrypting
# more than one file.
function encrypt_with_pass() {
    installed "gpg" || return 1

    local src="$1"
    local dst="$2"
    local pass="$3"

    if [ -z "$src" ] || [ -z "$dst" ] || [ -z "$pass" ]; then
        echo "Usage: encrypt_with_pass path/to/src path/to/dst passphrase" 1>&2
        return
    fi

    if [ ! -f "$src" ]; then
        echo "Source file $src doesn't exist" 1>&2
        return
    fi

    if [ -e "$dst" ]; then
        echo "Destination file $dst already exists" 1>&2
        return
    fi

    echo "$pass" | gpg --batch --yes --passphrase-fd 0 --output "$dst" \
        --symmetric "$src"
}

function encrypt() {
    installed "gpg" || return 1

    local src="$1"
    local dst="$2" # Optional

    if [ -z "$src" ]; then
        echo "Usage: encrypt path/to/src path/to/dst" 1>&2
        return
    fi

    # If source was provided but destination wasn't, set the default
    # destination by appending ".gpg"
    if [ -n "$src" ] && [ -z "$dst" ]; then
        dst="$src.gpg"
    fi

    echo -n "Enter passphrase: " && read -rs pass && echo
    echo -n "Re-enter passphrase: " && read -rs pass_confirm && echo

    [ ! "$pass" = "$pass_confirm" ] \
        && echo "Passphrase entries did not match" 1>&2 \
        && return

    encrypt_with_pass "$src" "$dst" "$pass"
}

# WARNING: This shouldn't be called from an interactive shell as the passphrase
# will be written in plaintext to $HISTFILE. It is only implemented so that
# scripts can avoid asking for the passphrase multiple times when decrypting
# more than one file.
function decrypt_with_pass() {
    installed "gpg" || return 1

    local src="$1"
    local dst="$2"
    local pass="$3"

    if [ -z "$src" ] || [ -z "$dst" ] || [ -z "$pass" ]; then
        echo "Usage: decrypt_with_pass path/to/src path/to/dst passphrase" 1>&2
        return
    fi

    if [ ! -f "$src" ]; then
        echo "Source file $src doesn't exist" 1>&2
        return
    fi

    if [ -e "$dst" ]; then
        echo "Destination file $dst already exists" 1>&2
        return
    fi

    echo "$pass" | gpg --batch --yes --passphrase-fd 0 --output "$dst" \
        --decrypt "$src"
}

function decrypt() {
    installed "gpg" || return 1

    local src="$1"
    local dst="$2"

    if [ -z "$src" ] || [ -z "$dst" ]; then
        echo "Usage: decrypt path/to/src path/to/dst" 1>&2
        return
    fi

    echo -n "Enter passphrase: " && read -rs pass && echo

    decrypt_with_pass "$src" "$dst" "$pass"
}

# Simple file search: Execute `find` with the most common parameters and hide
# errors
function f() {
    local search_term="$1"

    if [ -z "$search_term" ]; then
        echo "Usage: f <search_term>" 1>&2
        return
    fi

    find . -iname "*$search_term*" 2>/dev/null
}

function replace() {
    local before="$1"
    local after="$2"

    find . -type f -exec sed -i "s/$before/$after/g" {} \;
}

function apt_available_updates() {
    installed "apt" || return 1

    local num_updates

    num_updates="$(apt list --upgradeable 2>/dev/null | grep -cEv '^Listing\.\.\.')"
    echo "There are $num_updates updates available"
}

function apt_file_search() {
    installed "sudo" "apt-file" || return 1

    local file="$1"
    local skip_update="$2"

    local usage

    read -r -d '' usage <<'EOF'
Usage: apt_file_search <filename> [-s]

Search for apt packages that provide a specific file

Options:
    -s  Skip preliminary apt update step

Example:
    apt_file_search \"curl.h\"

Output:
    ...
    libcurl4-openssl-dev: /usr/include/x86_64-linux-gnu/curl/curl.h
    ...
EOF

    if [ -z "$file" ]; then
        yell "$usage"
        return 1
    fi

    if [ ! "$skip_update" = "-s" ]; then
        sudo apt-file update &>/dev/null &
        echo "Updating apt-file database; to skip this step pass the '-s' flag"
        wait
    fi

    apt-file find "$file"
}

function go_test_coverage() {
    installed "go" || return 1

    local tempfile

    tempfile="$(mktemp)"
    if go test -coverprofile="$tempfile"; then
        go tool cover -html="$tempfile"
    else
        1>&1 echo -e "ERROR: Tests failed; to view coverage anyways run:\ngo tool cover -html=\"$tempfile\""
    fi
}

# Converts a files binary contents to a nice hex representation and opens that
# in Neovim.
function viewhex {
    installed "xxd" "nvim" || return 1

    local path="$1"

    [ -z "$path" ] && yell "Usage: viewhex filename" && return 1

    local tmp
    tmp="$(mktemp)"
    local success="false"

    if xxd "$path" > "$tmp"; then
        success="true"
        nvim "$tmp"
    fi

    rm "$tmp"

    if [ "$success" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# This function reads a file and outputs a condensed text hex representation of
# its binary contents. For example, given the file hello.txt containing just
# the text:
#
#     Hello world, I am here and my name is Paul!
#
# The function can be used as follows:
#
#     tohex "hello.txt" "hello.hex.txt"
#
# As a result, hello.hex.txt will be created containing the following text:
#
#     48656c6c6f20776f726c642c204920616d206865726520616e64206d79206e616d65206973205061
#     756c210a
#
# Each line will contain up to 80 characters representing 40 bytes of data.
# This can be used to copy a binary file across an SSH session without SCP.
function tohex() {
    installed "hexdump" "od" || return 1

    local input_file="$1"
    local output_file="$2"

    # All of these work. The first two are effectively the same and don't add
    # any whitespace between bytes. The third adds a space between each byte in
    # the hex output.
    #hexdump -ve '1/1 "%.2x"' "$input_file" > "$output_file"
    hexdump -ve '40/1 "%.2x" 1 "\n"' "$input_file" > "$output_file"
    #od -tx1 -An -v "$input_file" > "$output_file"
}

# This function simply reverses the operation performed by tohex(). Given the
# text hex representation, it will output the original file.
#
# Example: tohex "hello.hex.txt" "hello.txt"
function fromhex() {
    installed "xxd" || return 1

    local input_file="$1"
    local output_file="$2"

    xxd -p -r "$input_file" "$output_file"
}

function git_show_tool {
    installed "git" || return 1

    local before after
    before="$(git log --oneline -n 2 | tail -n 1 | awk '{ print $1 }')"
    after="$(git log --oneline -n 2 | head -n 1 | awk '{ print $1 }')"

    git difftool "$before" "$after"
}

# Converts an image file from webp to jpg format. Requires webp and ImageMagick
# to be installed.
function webp_to_jpg() {
    installed "dwebp" "convert" || return 1

    local webp_file="$1"
    local jpg_file="$2"

    if [[ -z "$webp_file" || -z "$jpg_file" ]]; then
        1>&2 echo "Usage: webp_to_jpg path_to_img.webp path_to_img.jpg"
        return 1
    fi

    if ! dwebp "$webp_file" -o "$jpg_file.png"; then
        1>&2 echo "ERROR: failed to convert webp to intermediary png"
        return 1
    fi

    if ! convert "$webp_file" "$jpg_file"; then
        # Clean up the intermediary png
        rm "$jpg_file.png"

        1>&2 echo "ERROR: failed to convert intermediary png to jpg"
        return 1
    fi

    echo "Removing intermediary png"
    rm "$jpg_file.png"

    echo "Successfully converted $webp_file to $jpg_file"
}

# Converts an image file from jpg to png format.
function jpg_to_png() {
    installed "convert" || return 1

    local jpg_file="$1"
    local png_file="$2"

    if [[ -z "$jpg_file" || -z "$png_file" ]]; then
        1>&2 echo "Usage: jpg_to_png path_to_img.jpg path_to_img.png"
        return 1
    fi

    if ! convert "$jpg_file" "$png_file"; then
        1>&2 echo "ERROR: failed to convert jpg file $jpg_file to png format"
        return 1
    fi

    echo "Successfully converted $jpg_file to $png_file"
}

function docker_pss() {
    local tempfile
    tempfile="$(mktemp)"
    echo "ID Name Image" >> "$tempfile"
    docker ps --format "{{.ID}} {{.Names}} {{.Image}}" >> "$tempfile"
    column -t "$tempfile"
}

# Fuzzy directory changer
function fzfd() {
    local dir
    dir=$(find "${1:-.}" -path '*/\.*' -prune -o -type d -print 2>/dev/null \
            | fzf +m) && cd "$dir" || return 1
}

function is_restart_required() {
    if test -f "/var/run/reboot-required"; then
        echo "Yes"
    else
        echo "No"
    fi
}

function fd() {
    local selection

    if ! selection="$("$DOTFILES/cli/dot.py" fd choose "$1")"; then
        yell "ERROR: Directory selection failed"
        return 1
    fi

    [ -z "$selection" ] && return 0

    if [ ! -d "$selection" ]; then
        yell "ERROR: Selected directory \"$selection\" does not exist"
        return 1
    fi
    
    if ! cd "$selection"; then
        yell "ERROR: Failed to change directory to \"$selection\""
        return 1
    fi
}

function fd_add() {
    "$DOTFILES/cli/dot.py" fd add
}

function fd_edit() {
    "$DOTFILES/cli/dot.py" fd edit
}

function fd_update() {
    "$DOTFILES/cli/dot.py" fd update
}

function dec_to_hex() {
    if [ -z "$1" ]; then
        yell "Usage: dec_to_hex <decimal>"
        return 1
    fi

    printf "%d -> 0x%x\n" "$1" "$1"
}

function hex_to_dec() {
    if [ -z "$1" ]; then
        yell "Usage: hex_to_dec <hex>"
        return 1
    fi

    echo "0x$1 -> $((16#$1))"
}

function dot_cd() {
    cd "$DOTFILES" || return 1
}

function dot_push() {
    local cwd
    cwd="$(pwd)"
    cd "$DOTFILES" || return 1
    git push origin "$(git branch --show-current)"
    cd "$cwd" || return 1
}

function dot_pull() {
    local cwd
    cwd="$(pwd)"
    cd "$DOTFILES" || return 1
    git pull origin "$(git branch --show-current)"
    cd "$cwd" || return 1
}

function kssh() {
    installed "kitten" || return 1

    kitty +kitten ssh "$@"
}

# Diff two revisions in an SVN repository
function sdr() {
    local r1 r2 tmp_dir tmp_file

    r1="$1"
    r2="$2"

    if [ -z "$r1" ] || [ -z "$r2" ]; then
        echo "Usage: sdr <rev1> <rev2>"
        echo ""
        echo "Example: sdr 1837 1839"
        return 1
    fi

    tmp_dir="$HOME/tmp"
    tmp_file="$tmp_dir/diff.patch"

    mkdir -p "$tmp_dir"
    rm -f "$tmp_file"

    svn diff --readonly --diff-cmd=bcompare_svnrev -r "$1:$2"
}


# TODO: Allow specifying the output path
function tar_directory() {
    local dir path name

    dir="$1"

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        yell "Usage: tar_directory <directory>"
        return 1
    fi

    path="$(realpath $dir)"
    name="$(basename $path)"

    archive_path="/tmp/$name.tar.gz"

    if ! tar -czvf "$archive_path" -C "$path" . ; then
        yell "Failed to create archive"
        return 1
    fi

    echo "Created archive: $archive_path"
    echo "To extract it: "
    echo "untar_directory $archive_path ${path}-copy"
}

function untar_directory() {
    local archive_path dir_path

    archive_path="$1"
    dir_path="$2"

    if [ -z "$archive_path" ] || [ -z "$dir_path" ]; then
        yell "Usage: untar_directory <archive> <directory>"
        return 1
    fi

    if [ ! -f "$archive_path" ]; then
        yell "ERROR: Specified archive does not exist"
        return 1
    fi

    if [ -e "$dir_path" ]; then
        yell "ERROR: Specified directory path already exists"
        return 1
    fi

    if ! mkdir -p "$dir_path"; then
        yell "ERROR: Failed to create output directory"
        return 1
    fi

    if ! tar -xzvf "$archive_path" -C "$dir_path"; then
        yell "Failed to extract archive"
        return 1
    fi

    echo "Extracted archive: $archive_path"
    echo "To Directory:      $dir_path"
}

# Print the contents of an rpm package without extracting it.
function rpm_ls() {
    rpm -qlp "$1"
}

# Print the contents of a deb package without extracting it.
function deb_ls() {
    dpkg -c "$1"
}

# Completely restart bluetooth services
#
# I was having an issue at work where my headset would seemingly connect
# successfully but pavucontrol showed that Pulse didn't have an output for
# Bluetooth. I never bothered to fully debug but wrote up this quick function
# to just restart everything which in most cases would get things working.
#
# To use it, disconnect headset first, run the function, and then re-connect
# the headset.
#
# Hopefully when we move to Ubuntu 24.04 across devices which should be using
# pipewire by default for audio this will no longer be an issue.
function bluetooth_reset() {
    local sleep_between_steps

    if ! sudo -n true &> /dev/null; then
        echo "Resetting Bluetooth requires elevating to root: "
        if ! sudo echo "" > /dev/null; then
            yell "ERROR: Failed to elevate to root, aborting..."
            return 1
        fi
    fi

    # This is an arbitrary number of seconds that I picked that seemed to be
    # long enough for the function to consistently succeed. I'm sure there's a
    # better solution than just sleeping but this is already janky so who cares.
    sleep_between_steps="5"

    echo "Killing blueman processes..."
    killall blueman-applet &> /dev/null
    killall blueman-tray &> /dev/null
    killall blueman-manager &> /dev/null
    sleep $sleep_between_steps

    echo "Killing mpd..."
    killall mpd > /dev/null
    sleep $sleep_between_steps

    echo "Stopping bluetooth service..."
    sudo systemctl stop --now bluetooth
    sleep $sleep_between_steps

    echo "Killing pulseaudio..."
    pulseaudio --kill
    sleep $sleep_between_steps

    echo "Starting pulseaudio..."
    start-pulseaudio-x11 
    sleep $sleep_between_steps

    echo "Starting bluetooth service..."
    sudo systemctl start bluetooth
    sleep $sleep_between_steps

    echo "Starting mpd..."
    mpd
    sleep $sleep_between_steps

    echo "Bluetooth restarted!"
}

function set_volume()
{
    installed "amixer" || return 1

    local volume
    volume="$1"

    if [ "$volume" = "" ]; then
        volume="25"
    fi

    amixer -D pulse sset Master "${volume}%"
}

function _git_bash()
{
    local wezterm_exe="/mnt/c/Program Files/WezTerm/wezterm-gui.exe"
    local wezterm_args=(
        "start"
        "--domain" "local"
    )

    local bash_exe="C:\\Program Files\\Git\\bin\\bash.exe"
    local bash_args=(
        "-i" # Interactive
        "-l" # Login shell
    )

    "$wezterm_exe" "${wezterm_args[@]}" -- "$bash_exe" "${bash_args[@]}" &
}

function merge_pdfs()
{
    installed "pdftk" || return 1

    local input1="$1"
    local input2="$2"
    local output="$3"

    if [ -z "$input1" ] || [ -z "$input2" ] || [ -z "$output" ]; then
        echo "Usage: merge_pdfs <input1> <input2> <output>"
        echo ""
        echo "Example: merge_pdfs statement.pdf receipt.pdf statement_and_receipt.pdf"
        return 1
    fi

    pdftk "$input1" "$input2" cat output "$output"
}

hm-switch()
{
    local machine
    # TODO
    #machine="$(hostname -s)"
    machine="core"

    nix --extra-experimental-features "nix-command flakes" \
        run github:nix-community/home-manager -- \
        switch -b hm-bak --flake "$DOTFILES/nix#$machine"
}

str_contains()
{
    local string="$1"
    local substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

# Clone a Github repository to the specified path or a reasonable default if no
# path is provided
gh_clone()
{
    local org="$1"
    local repo="$2"
    local path="$3"

    local url="https://github.com/$org/$repo"

    if [ -z "$path" ]; then
        path="$HOME/src/github/$org/$repo"
    fi

    if [ -e "$path" ]; then
        yell "ERROR: Target directory '$path' already exists"
        return 1
    fi

    git clone "$url" "$path"
}

# TODO: Implement this
# Diff the current git repository with a previous commit using Beyond Compare.
# Copies the repository to a temp directory and checks out the specified
# commit/branch/tag. Then runs Beyond compare to do a directory comparison
# between the current directory and the temp directory.
git_diff_with()
{
    # TODO: Document this parameter
    local diff_target="$1"

    if [ -z "$diff_target" ]; then
        yell "ERROR: Missing argument <diff_target>"
        return 1
    fi

    # TODO: We could make this robust and walk up the file tree but for now
    # keep it simple
    if [ ! -d "./.git" ]; then
        yell "ERROR: Not at the root of a git repository"
        return 1
    fi

    local tmp_dir_name tmp_dir
    tmp_dir_name="$(basename $(pwd))_${diff_target}_diff"
    tmp_dir="$HOME/tmp/${tmp_dir_name}"
    
    # TODO: DEBUG REMOVE
    echo "tmp_dir = $tmp_dir"

    # TODO: Error handling below

    # Make sure the temporary directory doesn't already exist
    # TODO: Maybe if it does just leave it and use it? If we're targeting a
    # commit hash or tag it's unlikely to have changed. Could add a parameter
    # to force re-checkout?
    #rm -rf "$tmp_dir"

    if [ ! -d "$tmp_dir" ]; then
        # Make sure the parent directory exists
        if ! mkdir -p "$(dirname "$tmp_dir")"; then
            yell "ERROR: TODO0"
            return 1
        fi

        if ! cp -r "$(pwd)" "$tmp_dir"; then
            yell "ERROR: TODO1"
            return 1
        fi
    fi

    if ! cd "$tmp_dir"; then
        yell "ERROR: TODO2"
        return 1
    fi

    # TODO: Find a cleaner way to always get back to the previous working
    # directory. Maybe just execute all of this in a sub-shell?

    if ! git reset --hard; then
        cd -
        yell "ERROR: TODO31"
        return 1
    fi

    if ! git clean -fdx; then
        cd -
        yell "ERROR: TODO32"
        return 1
    fi

    if ! git checkout "$diff_target"; then
        cd -
        yell "ERROR: TODO3"
        return 1
    fi

    cd -

    local bcompare_exe
    # TODO: If WSL else...
    #bcompare_exe="bcompare"
    bcompare_exe="BCompare.exe"

    # TODO: Doesn't work on WSL because we need to canonicalize the path for Windows
    # e.g. /home/pewing/foo -> \\wsl.localhost\Ubuntu-24.04\home\pewing\foo
    echo -e "Executing:\n\"$bcompare_exe\" \"$(pwd)\" \"$tmp_dir\""
    #"$bcompare_exe" "$(pwd)" "$tmp_dir"
    "$bcompare_exe" \
        "\\\\WSL.LOCALHOST\\Ubuntu-24.04\\home\\pewing\\dot" \
        "\\\\WSL.LOCALHOST\\Ubuntu-24.04\\home\\pewing\\tmp\\${tmp_dir_name}"
}
