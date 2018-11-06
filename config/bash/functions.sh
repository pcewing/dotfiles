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

# Download a video from YouTube and rip the audio to an MP3
function youtube_mp3() {
    local url="$1"

    youtube-dl \
        -x \
        --audio-format "mp3" \
        "$url"
}

function youtube_playlist_mp3() {
    local url="$1"

    youtube-dl \
        --extract-audio \
        --audio-format mp3 \
        -o "%(title)s.%(ext)s" \
        "$url"
}

function git_diff_bc3() {
    git diff --name-only "$@" | while read filename; do
        git difftool "$@" --no-prompt "$filename" -t "bc3" &
    done
}

