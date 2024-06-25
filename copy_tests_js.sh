#!/bin/bash

# Specify the directories
# dirA="/home/me/Projects/Fuzzers/fuzzilli/wasm"
# dirB="/home/me/Projects/JSEngines/v8/test/mjsunit/wasm"
dirA=$1
dirB=$2

# Specify the regular expression
regex="worker-"
regex2="tier-up-testing-flag.js"

# Iterate over each item in directory B
for itemB in "$dirB"/*; do
    # Get the base name of the item
    itemB_base=$(basename "$itemB")

    # If the item's filename does not match the regular expression
    if [[ ! "$itemB_base" =~ $regex ]] && [[ ! "$itemB_base" =~ $regex2 ]]; then
        # Copy the item to directory A
        cp -r "$itemB" "$dirA"
    fi
done
