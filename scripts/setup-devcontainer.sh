#!/bin/bash

# Dev Container Template Setup Script
# Repository: https://github.com/poorleno1/dev-container-templates
# Usage: ./setup-devcontainer.sh [template-name] [target-directory]

set -e  # Exit on error

# Configuration
TEMPLATE_REPO="poorleno1/dev-container-templates"
SCRIPT_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_usage() {
    cat << EOF
🚀 Dev Container Template Setup Script v${SCRIPT_VERSION}

USAGE:
    $0 [template-name] [target-directory] [options]

EXAMPLES:
    $0 azure-terraform                    # Use azure-terraform template in current directory
    $0 azure-terraform ./my-project      # Use template in specific directory
    $0 --list                            # Show available templates
    $0 --help                            # Show this help

AVAILABLE TEMPLATES:
    azure-terraform     - Azure + Terraform + PowerShell + GitHub CLI
    python-data-science - Python + Jupyter + Data Science tools (coming soon)
    node-react          - Node.js + React development (coming soon)
    basic-linux         - Minimal Linux development environment (coming soon)

OPTIONS:
    --list              List available templates
    --help              Show this help message
    --version           Show script version
    --force             Overwrite existing .devcontainer directory
    --from-gist <id>    Use a gist instead of repository template

REQUIREMENTS:
    - GitHub CLI (gh) must be installed and authenticated
    - Git must be installed
    - Write permissions in target directory

EOF
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_requirements() {
    print_info "Checking requirements..."
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed or not in PATH"
        echo "Install it from: https://github.com/cli/cli#installation"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed or not in PATH"
        exit 1
    fi
    
    # Check if authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub CLI"
        echo "Run: gh auth login"
        exit 1
    fi
    
    print_success "All requirements met"
}

list_templates() {
    print_info "Available templates in repository $TEMPLATE_REPO:"
    echo
    
    # Try to get template list from repository
    if gh repo view "$TEMPLATE_REPO" &> /dev/null; then
        # List directories in the repo (templates)
        gh repo view "$TEMPLATE_REPO" --json name,description
        echo
        echo "📁 Template directories:"
        gh api "repos/$TEMPLATE_REPO/contents" --jq '.[].name | select(. != "README.md" and . != "scripts" and . != ".git")'
    else
        print_error "Cannot access repository $TEMPLATE_REPO"
        echo "Available templates based on script knowledge:"
        echo "  - azure-terraform"
        echo "  - python-data-science (coming soon)"
        echo "  - node-react (coming soon)"
        echo "  - basic-linux (coming soon)"
    fi
}

setup_from_gist() {
    local gist_id="$1"
    local target_dir="$2"
    
    print_info "Setting up from gist: $gist_id"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # Clone the gist
    if gh gist clone "$gist_id" "$temp_dir"; then
        # Create .devcontainer directory in target
        mkdir -p "$target_dir/.devcontainer"
        
        # Copy files from gist
        if [ -f "$temp_dir/devcontainer.json" ]; then
            cp "$temp_dir/devcontainer.json" "$target_dir/.devcontainer/"
            print_success "Copied devcontainer.json"
        fi
        
        # Copy any other files
        for file in "$temp_dir"/*; do
            if [ -f "$file" ] && [ "$(basename "$file")" != "devcontainer.json" ]; then
                cp "$file" "$target_dir/.devcontainer/"
                print_success "Copied $(basename "$file")"
            fi
        done
        
        # Clean up
        rm -rf "$temp_dir"
        
        print_success "Dev container setup from gist complete!"
        print_info "Next steps:"
        echo "  1. cd $target_dir"
        echo "  2. code ."
        echo "  3. Ctrl+Shift+P → 'Dev Containers: Rebuild Container'"
        
    else
        rm -rf "$temp_dir"
        print_error "Failed to clone gist $gist_id"
        exit 1
    fi
}

setup_from_template() {
    local template_name="$1"
    local target_dir="$2"
    local force_overwrite="$3"
    
    print_info "Setting up template: $template_name"
    print_info "Target directory: $target_dir"
    
    # Check if .devcontainer already exists
    if [ -d "$target_dir/.devcontainer" ] && [ "$force_overwrite" != "true" ]; then
        print_warning ".devcontainer directory already exists"
        echo "Use --force to overwrite, or manually remove the directory"
        exit 1
    fi
    
    # Create temporary directory for cloning
    local temp_dir=$(mktemp -d)
    
    print_info "Cloning template repository..."
    
    if gh repo clone "$TEMPLATE_REPO" "$temp_dir"; then
        # Check if template exists
        if [ ! -d "$temp_dir/$template_name" ]; then
            print_error "Template '$template_name' not found"
            print_info "Available templates:"
            ls -1 "$temp_dir" | grep -v "README.md\|scripts\|.git" || echo "No templates found"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Create target directory if it doesn't exist
        mkdir -p "$target_dir"
        
        # Copy the template
        if [ "$force_overwrite" = "true" ]; then
            rm -rf "$target_dir/.devcontainer"
        fi
        
        cp -r "$temp_dir/$template_name/.devcontainer" "$target_dir/"
        
        # Clean up
        rm -rf "$temp_dir"
        
        print_success "Template '$template_name' copied successfully!"
        print_info "Files created in: $target_dir/.devcontainer"
        
        # Show what was copied
        echo
        echo "📁 Files created:"
        ls -la "$target_dir/.devcontainer"
        
        print_success "Dev container setup complete!"
        print_info "Next steps:"
        echo "  1. cd $target_dir"
        echo "  2. code ."
        echo "  3. Ctrl+Shift+P → 'Dev Containers: Rebuild Container'"
        
    else
        rm -rf "$temp_dir"
        print_error "Failed to clone repository $TEMPLATE_REPO"
        print_info "Make sure you have access to the repository and are authenticated"
        exit 1
    fi
}

# Parse command line arguments
TEMPLATE_NAME=""
TARGET_DIR="."
FORCE_OVERWRITE="false"
FROM_GIST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            print_usage
            exit 0
            ;;
        --version|-v)
            echo "Dev Container Setup Script v${SCRIPT_VERSION}"
            exit 0
            ;;
        --list|-l)
            list_templates
            exit 0
            ;;
        --force|-f)
            FORCE_OVERWRITE="true"
            shift
            ;;
        --from-gist)
            FROM_GIST="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            if [ -z "$TEMPLATE_NAME" ]; then
                TEMPLATE_NAME="$1"
            elif [ -z "$TARGET_DIR" ] || [ "$TARGET_DIR" = "." ]; then
                TARGET_DIR="$1"
            else
                print_error "Too many arguments"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Main execution
echo "🚀 Dev Container Template Setup Script v${SCRIPT_VERSION}"
echo "Repository: https://github.com/$TEMPLATE_REPO"
echo

# Check requirements
check_requirements

# Handle gist setup
if [ -n "$FROM_GIST" ]; then
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="."
    fi
    setup_from_gist "$FROM_GIST" "$TARGET_DIR"
    exit 0
fi

# Validate arguments
if [ -z "$TEMPLATE_NAME" ]; then
    print_error "Template name is required"
    print_usage
    exit 1
fi

# Convert relative path to absolute
TARGET_DIR=$(realpath "$TARGET_DIR")

# Setup from template
setup_from_template "$TEMPLATE_NAME" "$TARGET_DIR" "$FORCE_OVERWRITE"