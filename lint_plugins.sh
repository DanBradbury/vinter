#!/bin/bash

# Script to clone and lint vim plugins using vinter
# Usage: ./lint_plugins.sh <repos_list_file>

set -e

REPOS_FILE="${1:-plugin_repos.txt}"
TEMP_DIR="./tmp_plugin_tests"
RESULTS_FILE="lint_results.txt"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if repos file exists
if [ ! -f "$REPOS_FILE" ]; then
    echo "Error: Repository list file '$REPOS_FILE' not found"
    echo "Usage: $0 <repos_list_file>"
    exit 1
fi

# Determine which vinter command to use
if command -v vinter &> /dev/null; then
    VINTER_CMD="vinter"
    echo "Using system vinter"
elif [ -f "bin/vinter" ] && [ -f "Gemfile" ]; then
    VINTER_CMD="bundle exec bin/vinter"
    echo "Using local vinter with bundle exec"
else
    echo "Error: vinter is not installed or not in PATH"
    echo "Please install it with: gem install vinter"
    echo "Or run from the vinter directory with bundle installed"
    exit 1
fi

# Create temp directory for cloning repos
mkdir -p "$TEMP_DIR"

# Initialize results
echo "Vim Plugin Linting Results - $(date)" > "$RESULTS_FILE"
echo "======================================" >> "$RESULTS_FILE"
echo ""

total_repos=0
passed_repos=0
failed_repos=0
skipped_repos=0

# Read repos from file
while IFS= read -r repo_url || [ -n "$repo_url" ]; do
    # Skip empty lines and comments
    [[ -z "$repo_url" || "$repo_url" =~ ^#.*$ ]] && continue

    total_repos=$((total_repos + 1))

    # Extract repo name from URL
    repo_name=$(basename "$repo_url" .git)

    echo ""
    echo "=================================="
    echo "Processing: $repo_name"
    echo "URL: $repo_url"
    echo "=================================="

    # Clean up any existing directory
    clone_path="$TEMP_DIR/$repo_name"
    rm -rf "$clone_path"

    # Clone the repository
    echo "Cloning repository..."
    if ! git clone --depth 1 "$repo_url" "$clone_path" 2>&1; then
        echo -e "${RED}✗ SKIP${NC}: Failed to clone $repo_name"
        echo "SKIP: $repo_name - Failed to clone" >> "$RESULTS_FILE"
        skipped_repos=$((skipped_repos + 1))
        continue
    fi

    echo "Clone successful"

    # Run vinter on the cloned directory
    echo "Running vinter..."
    if $VINTER_CMD "$clone_path" > "${clone_path}_lint.log" 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}: $repo_name has no errors"
        echo "PASS: $repo_name" >> "$RESULTS_FILE"
        passed_repos=$((passed_repos + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $repo_name has linting errors"
        echo "FAIL: $repo_name" >> "$RESULTS_FILE"
        failed_repos=$((failed_repos + 1))

        # Show a snippet of the errors
        echo ""
        echo "Error summary:"
        head -n 20 "${clone_path}_lint.log"
        if [ $(wc -l < "${clone_path}_lint.log") -gt 20 ]; then
            echo "... (see ${clone_path}_lint.log for full output)"
        fi
    fi

    # Save full lint output to results
    echo "  Lint output saved to: ${clone_path}_lint.log" >> "$RESULTS_FILE"

    # Optional: Clean up cloned directory to save space
    # Uncomment the next line if you want to remove cloned repos after linting
    # rm -rf "$clone_path"

done < "$REPOS_FILE"

# Print summary
echo ""
echo "========================================"
echo "Summary"
echo "========================================"
echo -e "Total repositories: $total_repos"
echo -e "${GREEN}Passed: $passed_repos${NC}"
echo -e "${RED}Failed: $failed_repos${NC}"
echo -e "${YELLOW}Skipped: $skipped_repos${NC}"
echo ""
echo "Results saved to: $RESULTS_FILE"
echo "Lint logs saved in: $TEMP_DIR/"

# Write summary to results file
echo "" >> "$RESULTS_FILE"
echo "======================================" >> "$RESULTS_FILE"
echo "Summary" >> "$RESULTS_FILE"
echo "======================================" >> "$RESULTS_FILE"
echo "Total repositories: $total_repos" >> "$RESULTS_FILE"
echo "Passed: $passed_repos" >> "$RESULTS_FILE"
echo "Failed: $failed_repos" >> "$RESULTS_FILE"
echo "Skipped: $skipped_repos" >> "$RESULTS_FILE"

# Exit with error code if any repos failed
if [ $failed_repos -gt 0 ]; then
    exit 1
else
    exit 0
fi
