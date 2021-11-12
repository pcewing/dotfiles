#!/usr/bin/env bash

function base16() {
    for i in {0..7}; do
        let j=$i+8
        printf "\x1b[38;5;${i}m colour${i}\t\x1b[38;5;${j}m colour${j}\n"
    done
}


# Create an executable bash file and open it in NeoVim
function nvims() {
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

script_path="$( realpath "$0" )"
script_dir="$( dirname "$script_path" )"

EOF

    chmod +x "$script_name"
    nvim "$script_name"
}

# Create an executable Python file and open it in NeoVim
function nvimp() {
    script_name="$1"

    if [[ -z "$script_name" ]]; then
        echo "Usage: nvimp <filename>" 1>&2
        return 1
    fi

    if [[ -e "$script_name" ]]; then
        echo "ERROR: File $script_name already exists" 1>&2
        return 1
    fi

    local template="#!/usr/bin/env python3

def main():
    pass

if __name__ == '__main__':
    main()
"

    echo "$template" > "$script_name"
    chmod +x "$script_name"
    nvim "$script_name"
}

function vman() {
    key="$1"

    rand=$[${RANDOM}%10000]
    tmp_file="/tmp/man_$rand.txt"

    man "$key" >> "$tmp_file"
    nvim "$tmp_file"

    rm "$tmp_file"
}

function sdr() {
    r1="$1"
    r2="$2"

    if [[ ! "$r1" = "" ]] && [[ ! "$r2" = "" ]]; then
        tmp_dir="$HOME/tmp"
        tmp_file="$tmp_dir/diff.patch"

        mkdir -p "$tmp_dir"
        rm -f "$tmp_file"

        svn diff --readonly --diff-cmd=bcompare_svnrev -r "$1:$2"
    else
        echo "Usage: sdr <rev1> <rev2>"
        echo ""
        echo "Example: sdr 1837 1839"
    fi
}

# Download just the audio from a YouTube video as an MP3 file
function yt-mp3() {
    youtube-dl -x --audio-format "mp3" "$1"
}

# Download a playlist from YouTube as a set of MP3 files
function ytpl-mp3() {
    youtube-dl --extract-audio --audio-format mp3 -o "%(title)s.%(ext)s" "$1"
}

function git_diff_bc3() {
    git diff --name-only "$@" | while read filename; do
        git difftool "$@" --no-prompt "$filename" -t "bc3" &
    done
}

# WARNING: This shouldn't be called from an interactive shell as the passphrase
# will be written in plaintext to $HISTFILE. It is only implemented so that
# scripts can avoid asking for the passphrase multiple times when encrypting
# more than one file.
function encrypt_with_pass() {
    local src="$1"
    local dst="$2"
    local pass="$3"

    [ -z "$src" -o -z "$dst" -o -z "$pass" ] \
        && echo "Usage: encrypt_with_pass path/to/src path/to/dst passphrase" 1>&2 \
        && return

    [ ! -f "$src" ] \
        && echo "Source file $src doesn't exist" 1>&2 \
        && return

    [ -e "$dst" ] \
        && echo "Destination file $dst already exists" 1>&2 \
        && return

    echo "$pass" | gpg --batch --yes --passphrase-fd 0 --output "$dst" \
        --symmetric "$src"
}

function encrypt() {
    local src="$1"
    local dst="$2" # Optional

    [ -z "$src" ] \
        && echo "Usage: encrypt path/to/src path/to/dst" 1>&2 \
        && return

    # If source was provided but destination wasn't, set the default
    # destination by appending ".gpg"
    [ ! -z "$src" -a -z "$dst" ] && dst="$src.gpg"

    echo -n "Enter passphrase: " && read -s pass && echo
    echo -n "Re-enter passphrase: " && read -s pass_confirm && echo

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
    local src="$1"
    local dst="$2"
    local pass="$3"

    [ -z "$src" -o -z "$dst" -o -z "$pass" ] \
        && echo "Usage: decrypt path/to/src path/to/dst passphrase" 1>&2 \
        && return

    [ ! -f "$src" ] \
        && echo "Source file $src doesn't exist" 1>&2 \
        && return

    [ -e "$dst" ] \
        && echo "Destination file $dst already exists" 1>&2 \
        && return

    echo "$pass" | gpg --batch --yes --passphrase-fd 0 --output "$dst" \
        --decrypt "$src"
}

function decrypt() {
    local src="$1"
    local dst="$2"

    [ -z "$src" -o -z "$dst" ] \
        && echo "Usage: decrypt path/to/src path/to/dst" 1>&2 \
        && return

    echo -n "Enter passphrase: " && read -s pass && echo

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
    local num_updates="$(apt list --upgradeable 2>/dev/null | grep -Ev '^Listing\.\.\.' | wc -l)"
    echo "There are $num_updates updates available"
}

function go_test_coverage() {
    local tempfile="$(mktemp)"
    go test -coverprofile="$tempfile" && go tool cover -html="$tempfile"
}

function viewhex {
    local path="$1"

    [ -z "$path" ] && yell "Usage: viewhex filename" && return 1

    local tmp="$(mktemp)"
    local success="false"

    xxd "$path" > "$tmp"
    [ "$?" = 0 ] && success="true" && nvim "$tmp"

    rm "$tmp"

    if [ "$success" = "true" ]; then
        return 0
    else
        return 1
    fi
}

function git_show_tool {
    local before="$(git log --oneline -n 2 | tail -n 1 | awk '{ print $1 }')"
    local after="$(git log --oneline -n 2 | head -n 1 | awk '{ print $1 }')"

    git difftool "$before" "$after"
}

# This isn't all that useful because this is already a single line command but
# I'm mostly adding this so I can remember the proper way to check if a command
# exists in $PATH. To use in an if statement:
# if command -v "$cmd" &>/dev/null; then echo "true"; fi
function is_installed() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# Converts an image file from webp to jpg format. Requires webp and ImageMagick
# to be installed.
function webp_to_jpg() {
    local webp_file="$1"
    local jpg_file="$2"

    if [[ -z "$webp_file" || -z "$jpg_file" ]]; then
        1>&2 echo "Usage: webp_to_jpg path_to_img.webp path_to_img.jpg"
        return 1
    fi

    if ! command -v "dwebp" &>/dev/null; then
        1>&2 echo "ERROR: dwebp missing; install it via 'apt install webp'"
        return 1
    fi

    if ! command -v "convert" &>/dev/null; then
        1>&2 echo "ERROR: convert missing; install it via 'apt install imagemagick'"
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
