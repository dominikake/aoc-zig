#!/bin/bash

# Learning Guide Update Script
# Called after successful AoC submission

YEAR=$1
DAY=$2
SOLUTION_FILE=$3

if [ -z "$YEAR" ] || [ -z "$DAY" ] || [ -z "$SOLUTION_FILE" ]; then
    echo "Usage: update-learning-guide.sh <year> <day> <solution_file>"
    exit 1
fi

# Build and run learning guide agent
zig build learning-guide
if [ $? -eq 0 ]; then
    ./.zig-cache/o/*/learning-guide-agent "$YEAR" "$DAY" "$SOLUTION_FILE"
    echo "Learning guide updated for Day $DAY"
else
    echo "Failed to build learning guide agent"
    exit 1
fi