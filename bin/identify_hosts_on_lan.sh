#!/bin/bash
# identify_hosts_on_lan.sh
# Description: Scans a subnet in parallel on Linux and resolves hostnames.

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

# Define the subnet prefix (change this if your LAN uses a different range)
SUBNET_PREFIX="192.168.1"

echo "Scanning network ${SUBNET_PREFIX}.1 to ${SUBNET_PREFIX}.254 in parallel..."

# Temporary file to collect discovered active IPs across background jobs
TEMP_FILE=$(mktemp)

# 1. Scan the network utilizing parallel background jobs
for i in {1..254}; do
    (
        IP="${SUBNET_PREFIX}.${i}"

        # Ping the IP address (-c 1 = 1 packet, -W 1 = 1 second timeout)
        if ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
            echo "$IP" >> "$TEMP_FILE"
        fi
    ) & # The ampersand runs this loop iteration in the background
done

# Wait for all background ping jobs to finish
wait

# Read active hosts into an array
if [ -s "$TEMP_FILE" ]; then
    mapfile -t ACTIVE_HOSTS < "$TEMP_FILE"
else
    ACTIVE_HOSTS=()
fi

# Clean up the temporary file
rm -f "$TEMP_FILE"

# Check if any hosts were found
if [ ${#ACTIVE_HOSTS[@]} -eq 0 ]; then
    echo "No active hosts discovered on the network."
    exit 0
fi

echo -e "\nDiscovered ${#ACTIVE_HOSTS[@]} active host(s). Resolving hostnames...\n"

# Print a formatted table header
printf "%-18s %s\n" "IP Address" "Hostname"
printf "%-18s %s\n" "----------" "--------"

# 2. Dynamically resolve hostnames for discovered IPs
for TARGET_IP in "${ACTIVE_HOSTS[@]}"; do
    # Attempt to resolve the hostname using 'host' (or fallback to 'getent')
    if command -v host >/dev/null 2>&1; then
        # Extract the hostname from the 'host' command output
        HOSTNAME=$(host "$TARGET_IP" | awk '/pointer/ {print $5}' | sed 's/\.$//')
    else
        # Fallback to getent hosts if the 'host' utility isn't installed
        HOSTNAME=$(getent hosts "$TARGET_IP" | awk '{print $2}')
    fi

    # If no hostname is found, set a default message
    if [ -z "$HOSTNAME" ]; then
        HOSTNAME="Unknown (No DNS Record)"
    fi

    # Output the structured row
    printf "%-18s %s\n" "$TARGET_IP" "$HOSTNAME"
done
