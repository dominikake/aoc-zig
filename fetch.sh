#!/usr/bin/env bash

# ./fetch.sh YYYY DAY [OPTIONS]
# ./fetch.sh 2025 1
# ./fetch.sh 2025 1 --force  # Re-download everything
# ./fetch.sh 2025 1 --puzzle # Only fetch puzzle description

set -euo pipefail

YEAR="$1"
DAY="$2"
FORCE=false
PUZZLE_ONLY=false

# Parse additional arguments
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --puzzle|-p)
            PUZZLE_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./fetch.sh YYYY DAY [--force] [--puzzle]"
            exit 1
            ;;
    esac
done

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

# Function to check if part 2 is available
check_part2_available() {
    local puzzle_html
    puzzle_html=$(curl -s "https://adventofcode.com/${YEAR}/day/${DAY}" \
        -H "Cookie: session=${SESSION}")

    # Check if part 2 section exists in the HTML
    if echo "$puzzle_html" | grep -q "Your puzzle answer was"; then
        return 0  # Part 2 is available
    else
        return 1  # Part 2 not yet available
    fi
}

# Download input (unless puzzle-only mode)
if [[ "$PUZZLE_ONLY" != "true" ]]; then
    if [[ "$FORCE" == "true" || ! -f "$INPUT_FILE" ]]; then
        echo "Downloading input for ${YEAR} day ${DAY}..."
        curl "https://adventofcode.com/${YEAR}/day/${DAY}/input" \
            -H "Cookie: session=${SESSION}" \
            --compressed \
            -o "$INPUT_FILE"
        echo "Saved input as $INPUT_FILE"
    else
        echo "Input file already exists: $INPUT_FILE"
    fi
fi

# Create or update solution file
if [[ ! -f "$SOLUTION_FILE" || "$FORCE" == "true" ]]; then
    echo "Creating/updating solution file: $SOLUTION_FILE"

    # Check if part 2 is available
    if check_part2_available; then
        echo "Part 2 is available!"
        PART2_COMMENT="// TODO: Implement part 2 solution"
    else
        echo "Part 2 not yet unlocked."
        PART2_COMMENT="// TODO: Complete part 1 first to unlock part 2"
    fi

    cat > "$SOLUTION_FILE" << EOF
pub fn part1(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 1 solution
    return null;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    $PART2_COMMENT
    return null;
}

const std = @import("std");
EOF
    echo "Solution template created/updated. Start coding!"
else
    echo "Solution file already exists: $SOLUTION_FILE"
    echo "Use --force to overwrite."
fi

echo ""
echo "Next steps:"
echo "  1. Edit $SOLUTION_FILE"
echo "  2. Run: zig build solve -Dday=$DAY -Dyear=$YEAR"
echo "  3. Submit: ./submit.sh $YEAR $DAY 1 \"your_answer\""
if check_part2_available; then
    echo "  4. Part 2 is available! Run: zig build solve -Dday=$DAY -Dyear=$YEAR -Dpart=2"
    echo "  5. Submit part 2: ./submit.sh $YEAR $DAY 2 \"your_answer\""
else
    echo "  4. Complete part 1 to unlock part 2"
fi
echo ""
echo "Options:"
echo "  --force: Re-download everything"
echo "  --puzzle: Only fetch puzzle description"