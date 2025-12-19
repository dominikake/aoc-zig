#!/usr/bin/env bash

# Test script for automated AoC workflow
# Usage: ./test-workflow.sh <year> <day> <concept>

YEAR="$1"
DAY="$2" 
CONCEPT="$3"

echo "=== Testing Automated AoC Workflow ==="
echo "Year: $YEAR, Day: $DAY"
echo "Concept: $CONCEPT"
echo ""

# Step 1: Ensure solution exists
if [[ ! -f "$YEAR/day_$(printf "%02d" $DAY).zig" ]]; then
    echo "❌ Solution file not found"
    exit 1
fi

# Step 2: Test solution works
echo "Step 1: Testing solution..."
PART1_OUTPUT=$(timeout 30s zig build solve -Dyear=$YEAR -Dday=$DAY -Dpart=1 2>&1)
PART1_RESULT=$(echo "$PART1_OUTPUT" | tail -1)
if [[ -z "$PART1_RESULT" || "$PART1_RESULT" == "No result" ]]; then
    echo "❌ Part 1 failed to run"
    exit 1
fi
echo "✅ Part 1 answer: $PART1_RESULT"

# Step 3: Check if already submitted
if [[ -f "$HOME/.cache/aoc/${YEAR}_${DAY}_1.completed" ]]; then
    echo "ℹ️  Part 1 already submitted"
else
    echo "Step 2: Submitting Part 1..."
    ./submit.sh $YEAR $DAY 1 "$PART1_RESULT" --force > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "✅ Part 1 submitted successfully"
    else
        echo "⚠️  Part 1 submission failed (rate limited or incorrect)"
    fi
fi

# Step 4: Test Part 2 if available
echo "Step 3: Testing Part 2..."
PART2_OUTPUT=$(timeout 30s zig build solve -Dyear=$YEAR -Dday=$DAY -Dpart=2 2>&1)
PART2_RESULT=$(echo "$PART2_OUTPUT" | tail -1)
if [[ -n "$PART2_RESULT" && "$PART2_RESULT" != "No result" ]]; then
    echo "✅ Part 2 answer: $PART2_RESULT"
    
    if [[ -f "$HOME/.cache/aoc/${YEAR}_${DAY}_2.completed" ]]; then
        echo "ℹ️  Part 2 already submitted"
    else
        echo "Step 4: Submitting Part 2..."
        ./submit.sh $YEAR $DAY 2 "$PART2_RESULT" --force > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "✅ Part 2 submitted successfully"
        else
            echo "⚠️  Part 2 submission failed (rate limited or incorrect)"
        fi
    fi
else
    echo "ℹ️  Part 2 not available or failed"
fi

echo ""
echo "=== Workflow Complete ==="