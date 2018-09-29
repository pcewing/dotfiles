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

