# Learning Guide System

## Overview
This system automatically generates educational learning guides after successful Advent of Code solutions, focusing on TAOCP concepts, programming principles, and Zig-specific features.

## Directory Structure
```
learning-guide/
├── agents/
│   ├── learning-guide-agent.zig    # Core agent logic
│   └── main.zig                # CLI interface
├── templates/
│   └── day-template.md           # Template for new guides
├── 2025/
│   └── day-01-learning-guide.md  # Generated guides
├── build.zig                    # Build system integration
└── README.md                    # This file
```

## Usage

### Manual Update
```bash
# Update learning guide for a specific day
zig build learning-guide
./.zig-cache/o/*/learning-guide-agent <year> <day> <solution_file>

# Example
zig build learning-guide
./.zig-cache/o/*/learning-guide-agent 2025 1 2025/day_01.zig
```

### Script Integration
```bash
# Using the integration script
./update-learning-guide.sh <year> <day> <solution_file>

# Example
./update-learning-guide.sh 2025 1 2025/day_01.zig
```

## Learning Guide Components

Each generated learning guide includes:

1. **Problem Breakdown**: High-level understanding of each part
2. **TAOCP Concepts**: Mathematical and algorithmic principles applied
3. **Programming Concepts**: General computer science concepts
4. **Zig-Specific Concepts**: Language features and syntax
5. **Learning Exercises**: Practice problems for reinforcement
6. **Key Insights**: Important takeaways and patterns

## Educational Philosophy

- **Learning Over Answers**: Focus on concepts, not solutions
- **Progressive Complexity**: Build from simple to advanced
- **Practical Application**: Real-world programming techniques
- **Cross-Reference**: Connect concepts across days

## Integration with AoC Workflow

The learning guide system is designed to integrate with the existing AoC workflow:

1. **Solve Problem**: Implement solution using TAOCP concepts
2. **Submit Answer**: Use `submit.sh` script
3. **Generate Guide**: Automatically update learning guide
4. **Review Learning**: Study concepts and exercises

## Future Enhancements

- **Automatic Concept Detection**: Parse solutions for concept usage
- **Interactive Exercises**: Generate practice problems
- **Cross-Day Analytics**: Track concept progression
- **Template Customization**: Adapt to different problem types

## Agent Architecture

The learning guide agent uses a modular design:

- **ConceptAnalysis**: Structured data for extracted concepts
- **LearningGuideAgent**: Core logic for guide generation
- **CLI Interface**: Command-line tool for manual updates
- **Build Integration**: Zig build system integration

This system ensures that every successful solution contributes to a comprehensive learning resource for understanding TAOCP concepts and Zig programming.