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
function yt-mp3() {
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

function docker_pss() {
    local tempfile
    tempfile="$(mktemp)"
    echo "ID Name Image" >> "$tempfile"
    docker ps --format "{{.ID}} {{.Names}} {{.Image}}" >> "$tempfile"
    column -t "$tempfile"
}

# It can be useful to have scripts that automatically update the entries in
# ~/.fd_dirs, for example when maintaining multiple clones of a repo to work on
# different branches simultaneously. So, this function looks for executable
# scripts in ~/.config/fd/fd.d/ and then executes all of them.
function fd_update() {
    local fd_script

    # No need to check if the directory exists or if it's empty because we're
    # already ensuring the glob results are executable files before we try to
    # run them which properly handles those cases.
    for fd_script in "$HOME/.config/fd/fd.d"/*; do
        if [ -f "$fd_script" ] && [ -x "$fd_script" ]; then
            "$fd_script"
        fi
    done
}

# Fuzzy directory changer
function fd() {
    local query fd_dirs_file key value dir

    installed "fzf" || return 1

    fd_update

    query=""
    if [ -n "$1" ]; then
        query="$1"
    fi

    fd_dirs_file="$HOME/.fd_dirs"

    if [ ! -f "$fd_dirs_file" ]; then
        cat << EOF > "$fd_dirs_file"
# File format:
# - name=path
# - Blank lines and lines beginning with "#" are stripped

# Examples
example1=/home/paul/Documents
EOF
    fi

    keys="$(
        grep -vP '(^ *$)|(^#.*)' "$fd_dirs_file" | \
        sed -e 's/=.*//g'
    )"

    key="$(echo "$keys" | fzf --query "$query" )"

    value="$(
        grep -P "^$key=.*$" "$fd_dirs_file" | \
        sed -e 's/.*=//g'
    )"

    if [ -n "$value" ]; then
        # Expand variables like $HOME
        dir="$(eval echo "$value")"

        if [ -d "$dir" ]; then
            cd "$dir" || return 1
        else
            yell "ERROR: Directory \"$dir\" does not exist"
        fi
    fi
}

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

function fd_add() {
    local key

    key="$1"
    if [ -z "$key" ]; then
        # Get the full path to the current directory
        key="$(pwd)"

        # Replace $HOME with ~
        key="${key/$HOME/\~}"
    fi

    if grep -E "^$key=" ~/.fd_dirs &>/dev/null; then
        yell "ERROR: Key \"$key\" already exists in ~/.fd_dirs"
        return 1
    fi

    path="$( realpath "$(pwd)" )"
    echo "${key}=${path}" >> ~/.fd_dirs
}

function fd_edit() {
    nvim ~/.fd_dirs
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

function dot-cd() {
    cd "$DOTFILES" || return 1
}

function dot-push() {
    local cwd
    cwd="$(pwd)"
    cd "$DOTFILES" || return 1
    git push origin "$(git branch --show-current)"
    cd "$cwd" || return 1
}

function dot-pull() {
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
