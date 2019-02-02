try()
{
    "$@" > ~/.command_log 2>&1
    local ret_val=$?
  
    if [ $ret_val -eq 0 ]; then
        echo "SUCCESS"
    else
        echo "FAILURE"
        echo "Command: $*"
        echo "Output:"
        cat ~/.command_log
        exit 1
    fi
}

apt_update(){ echo "Updating package lists... "; try sudo apt-get -y update; }
apt_upgrade(){ echo "Upgrading packages... "; try sudo apt-get -y upgrade; }
apt_install(){ echo "Installing $1... "; try sudo apt-get -y install "$1"; }
apt_add_repo(){ echo "Adding $1 repository... "; try sudo add-apt-repository -y "ppa:$1"; }

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

function nvims() {
    script_name="$1"

    if [[ -e "$script_name" ]]; then
        return 1
    else
        echo "#!/usr/bin/env bash" >> "$script_name"
        chmod +x "$script_name"
        nvim "$script_name"
    fi
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

