#!/usr/bin/env bash

# ./fetch.sh YYYY DAY
# ./fetch.sh 2025 1

set -euo pipefail

YEAR="$1"
DAY="$2"

COOKIE_FILE="$HOME/.config/aoc/session.cookie"
INPUT_DIR="input/${YEAR}"
INPUT_FILE="${INPUT_DIR}/day$(printf "%02d" "$DAY").txt"
SOLUTION_DIR="${YEAR}"
SOLUTION_FILE="${SOLUTION_DIR}/day_$(printf "%02d" "$DAY").zig"

# Create directories
mkdir -p "$INPUT_DIR"
mkdir -p "$SOLUTION_DIR"

# Check session cookie
if [[ ! -f "$COOKIE_FILE" ]]; then
    echo "Found no session cookie file at: $COOKIE_FILE"
    echo "Create it with your Advent of Code session token"
    exit 1
fi

SESSION=$(cat "$COOKIE_FILE")

# Download input
echo "Downloading input for ${YEAR} day ${DAY}..."
curl "https://adventofcode.com/${YEAR}/day/${DAY}/input" \
    -H "Cookie: session=${SESSION}" \
    --compressed \
    -o "$INPUT_FILE"

echo "Saved input as $INPUT_FILE"

# Create solution file if it doesn't exist
if [[ ! -f "$SOLUTION_FILE" ]]; then
    echo "Creating solution file: $SOLUTION_FILE"
    cat > "$SOLUTION_FILE" << EOF
pub fn part1(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 1 solution
    return null;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 2 solution
    return null;
}

const std = @import("std");
EOF
    echo "Solution template created. Start coding!"
else
    echo "Solution file already exists: $SOLUTION_FILE"
fi

echo ""
echo "Next steps:"
echo "  1. Edit $SOLUTION_FILE"
echo "  2. Run: zig build solve -Dday=$DAY -Dyear=$YEAR"
echo "  3. Test: zig build test -Dday=$DAY -Dyear=$YEAR"