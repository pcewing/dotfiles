#!/usr/bin/env bash

function base16() {
    for i in {0..7}; do
        let j=$i+8
        printf "\x1b[38;5;${i}m colour${i}\t\x1b[38;5;${j}m colour${j}\n"
    done
}


# print available colors and their numbers
function colours() {
    for i in {0..255}; do
        printf "\x1b[38;5;${i}m colour${i}"
        if (( $i % 5 == 0 )); then
            printf "\n"
        else
            printf "\t"
        fi
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

    echo "#!/usr/bin/env bash" >> "$script_name"
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

function git_diff_meld() {
    git diff --name-only "$@" | while read filename; do
        git difftool "$@" --no-prompt "$filename" -t "meld" &
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

