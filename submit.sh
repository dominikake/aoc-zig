#!/usr/bin/env bash

# ./submit.sh YYYY DAY LEVEL ANSWER [--force]
# ./submit.sh 2025 1 1 "12345"
# ./submit.sh 2025 1 1 "12345" --force  (non-interactive mode)

set -euo pipefail

YEAR="$1"
DAY="$2" 
LEVEL="$3"
ANSWER="$4"
FORCE_MODE="${5:-}"

COOKIE_FILE="$HOME/.config/aoc/session.cookie"
CACHE_DIR="$HOME/.cache/aoc"
CACHE_FILE="$CACHE_DIR/${YEAR}_${DAY}_${LEVEL}.completed"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if already completed (skip in force mode)
if [[ -f "$CACHE_FILE" && "$FORCE_MODE" != "--force" ]]; then
    echo "⚠️  Part $LEVEL for $YEAR Day $DAY has already been completed."
    echo "Use --force to submit anyway (not recommended)."
    exit 1
fi

# Check session cookie
if [[ ! -f "$COOKIE_FILE" ]]; then
    echo "Found no session cookie file at: $COOKIE_FILE"
    echo "Create it with your Advent of Code session token"
    exit 1
fi

SESSION=$(cat "$COOKIE_FILE")

# Validate inputs
if [[ -z "$YEAR" || -z "$DAY" || -z "$LEVEL" || -z "$ANSWER" ]]; then
    echo "Usage: ./submit.sh YYYY DAY LEVEL ANSWER"
    echo "Example: ./submit.sh 2025 1 1 \"12345\""
    exit 1
fi

if [[ "$LEVEL" != "1" && "$LEVEL" != "2" ]]; then
    echo "Error: LEVEL must be 1 or 2"
    exit 1
fi

# Confirmation prompt (skip in force mode)
if [[ "$FORCE_MODE" != "--force" ]]; then
    echo "You are about to submit an answer for Advent of Code $YEAR Day $DAY, Part $LEVEL"
    echo "Answer: $ANSWER"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Submission cancelled."
        exit 0
    fi
else
    echo "Force mode: submitting without confirmation"
fi

# Submit answer
echo "Submitting answer..."

RESPONSE=$(curl -s -X POST "https://adventofcode.com/$YEAR/day/$DAY/answer" \
    -H "Cookie: session=$SESSION" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "level=$LEVEL" \
    -d "answer=$ANSWER")

# Parse response
if echo "$RESPONSE" | grep -q "That's the right answer"; then
    echo "✅ CORRECT! That's the right answer!"
    # Cache the successful submission
    echo "$ANSWER" > "$CACHE_FILE"
    echo "Submission cached. You won't be prompted to submit this part again."
elif echo "$RESPONSE" | grep -q "That's not the right answer"; then
    echo "❌ INCORRECT: That's not the right answer."
    echo "Response details:"
    echo "$RESPONSE" | grep -A 5 -B 5 "That's not the right answer"
elif echo "$RESPONSE" | grep -q "You gave an answer too recently"; then
    echo "⏱️  RATE LIMITED: You gave an answer too recently."
    echo "Wait a bit before trying again."
elif echo "$RESPONSE" | grep -q "You don't seem to be solving the right level"; then
    echo "⚠️  WRONG LEVEL: You don't seem to be solving the right level."
else
    echo "❓ UNKNOWN RESPONSE:"
    echo "$RESPONSE"
fi