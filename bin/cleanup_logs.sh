#!/usr/bin/env bash

# Delete any log files that haven't been touched in 14 days
days="14"
logdir="$HOME/.logs"
[ -d "$logdir" ] && find "$logdir" -ctime +$days -type f -exec rm {} \;

