function cdl {
    cd $1 && echo "Now in: $(pwd)\nContents:\n" && ls
}

# Clone the running terminal
function term {
    # TODO: The cloned terminal will close when the parent closes; find a
    # better way to implement this
    urxvt -cd $(pwd) &
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
