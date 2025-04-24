#!/bin/bash
#
# Pre-commit hook to ensure that each system/subsystem has a README.md file
#
# To install:
# 1. Copy this file to .git/hooks/pre-commit
# 2. Make it executable: chmod +x .git/hooks/pre-commit
#

# Get a list of all staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

# Define system directories to check
SYSTEM_DIRS=(
    "camera"
    "environment"
    "scripts/motion"
    "scripts/collision_materials"
    "scripts/stage"
    "scripts/player"
    "scripts/effects"
    "visual_background"
    "game"
)

# Define subsystem directories to check
SUBSYSTEM_DIRS=(
    "camera/subsystems/follow"
    "camera/subsystems/zoom"
    "camera/subsystems/slowmo"
    "camera/debug"
    "environment/managers"
    "environment/theme"
    "environment/biome"
    "environment/debug"
    "scripts/motion/subsystems/bounce"
    "scripts/motion/subsystems/boost"
    "scripts/motion/subsystems/launch"
    "scripts/obstacles"
    "scripts/stage/components"
    "scripts/stage/content"
    "scripts/stage/resources"
    "scripts/stage/strategies"
    "visual_background/debug"
)

# Function to check if a directory has a README.md file
check_readme() {
    local dir=$1
    if [ -d "$dir" ] && [ ! -f "$dir/README.md" ]; then
        echo "Error: $dir is missing a README.md file"
        echo "Please create a README.md file for this system/subsystem before committing"
        return 1
    fi
    return 0
}

# Check if any staged files are in a system/subsystem directory
NEEDS_README=false
for file in $STAGED_FILES; do
    # Check if file is in a system directory
    for dir in "${SYSTEM_DIRS[@]}"; do
        if [[ $file == $dir/* ]]; then
            if ! check_readme "$dir"; then
                NEEDS_README=true
            fi
        fi
    done
    
    # Check if file is in a subsystem directory
    for dir in "${SUBSYSTEM_DIRS[@]}"; do
        if [[ $file == $dir/* ]]; then
            if ! check_readme "$dir"; then
                NEEDS_README=true
            fi
        fi
    done
done

# If any directory is missing a README.md, abort the commit
if [ "$NEEDS_README" = true ]; then
    echo "Commit aborted due to missing README.md file(s)"
    exit 1
fi

# All checks passed
exit 0
