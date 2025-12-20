#!/bin/bash

# VSCode Marketplace Deployment Script
# This script helps you deploy the YAML Embedded Languages extension to the VSCode Marketplace

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  ${1}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Parse command line arguments
DRY_RUN=false
SKIP_TESTS=false
AUTO_BUMP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --patch|--minor|--major)
            AUTO_BUMP="${1#--}"
            shift
            ;;
        --help)
            echo "VSCode Marketplace Deployment Script"
            echo ""
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Package the extension but don't publish"
            echo "  --skip-tests    Skip running tests before deployment"
            echo "  --patch         Auto-bump patch version (0.1.9 -> 0.1.10)"
            echo "  --minor         Auto-bump minor version (0.1.9 -> 0.2.0)"
            echo "  --major         Auto-bump major version (0.1.9 -> 1.0.0)"
            echo "  --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./deploy.sh --dry-run           # Test packaging without publishing"
            echo "  ./deploy.sh --patch             # Bump patch and publish"
            echo "  ./deploy.sh --minor --skip-tests # Bump minor, skip tests, and publish"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "YAML Embedded Languages - VSCode Marketplace Deployment"

# Check if running in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found! Please run this script from the project root."
    exit 1
fi

# Check if vsce is installed
if ! command -v vsce &> /dev/null; then
    print_warning "vsce (Visual Studio Code Extension Manager) is not installed globally."
    print_info "Installing vsce..."
    npm install -g @vscode/vsce
    print_success "vsce installed successfully"
fi

# Check publisher name
PUBLISHER=$(node -p "require('./package.json').publisher")
if [ "$PUBLISHER" == "your-publisher-name" ] || [ -z "$PUBLISHER" ]; then
    print_error "Publisher name not set in package.json!"
    echo ""
    echo "Please follow these steps:"
    echo "1. Go to https://marketplace.visualstudio.com/manage"
    echo "2. Create a publisher if you don't have one"
    echo "3. Update the 'publisher' field in package.json with your publisher name"
    echo ""
    exit 1
fi

print_success "Publisher: $PUBLISHER"

# Get current version
CURRENT_VERSION=$(node -p "require('./package.json').version")
print_info "Current version: $CURRENT_VERSION"

# Auto-bump version if specified
if [ -n "$AUTO_BUMP" ]; then
    print_info "Auto-bumping $AUTO_BUMP version..."
    npm version $AUTO_BUMP --no-git-tag-version
    NEW_VERSION=$(node -p "require('./package.json').version")
    print_success "Version bumped: $CURRENT_VERSION → $NEW_VERSION"
    CURRENT_VERSION=$NEW_VERSION
fi

# Check if token is set
if [ -z "$VSCE_PAT" ]; then
    print_warning "VSCE_PAT environment variable not set."
    echo ""
    echo "You have two options:"
    echo "1. Set VSCE_PAT environment variable: export VSCE_PAT='your-token'"
    echo "2. You'll be prompted for your token during publish"
    echo ""
    echo "To get a Personal Access Token:"
    echo "1. Go to https://dev.azure.com/{your-org}/_usersSettings/tokens"
    echo "2. Create a new token with 'Marketplace > Manage' scope"
    echo "3. Set it as VSCE_PAT environment variable"
    echo ""

    if [ "$DRY_RUN" == "false" ]; then
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled."
            exit 0
        fi
    fi
else
    print_success "VSCE_PAT token found"
fi

# Clean previous builds
print_header "Cleaning Previous Builds"
print_info "Removing old build artifacts..."
rm -rf out/
rm -f *.vsix
print_success "Clean completed"

# Install dependencies
print_header "Installing Dependencies"
print_info "Running npm install..."
npm install
print_success "Dependencies installed"

# Run linting
print_header "Running Linter"
print_info "Running ESLint..."
if npm run lint; then
    print_success "Linting passed"
else
    print_error "Linting failed! Please fix the errors before deploying."
    exit 1
fi

# Run tests (if not skipped)
if [ "$SKIP_TESTS" == "false" ]; then
    print_header "Running Tests"
    print_info "Running test suite..."
    if npm test; then
        print_success "Tests passed"
    else
        print_warning "Tests failed, but continuing..."
        read -p "Continue with deployment? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled."
            exit 0
        fi
    fi
else
    print_warning "Skipping tests (--skip-tests flag used)"
fi

# Compile TypeScript
print_header "Compiling TypeScript"
print_info "Running TypeScript compiler..."
if npm run compile; then
    print_success "Compilation successful"
else
    print_error "Compilation failed!"
    exit 1
fi

# Package the extension
print_header "Packaging Extension"
print_info "Creating .vsix package..."
if vsce package; then
    VSIX_FILE="yaml-embedded-languages-${CURRENT_VERSION}.vsix"
    print_success "Package created: $VSIX_FILE"

    # Show package size
    SIZE=$(ls -lh "$VSIX_FILE" | awk '{print $5}')
    print_info "Package size: $SIZE"
else
    print_error "Packaging failed!"
    exit 1
fi

# Publish (if not dry-run)
if [ "$DRY_RUN" == "true" ]; then
    print_header "Dry Run Complete"
    print_warning "This was a dry run. The extension was packaged but not published."
    print_info "To test the extension locally, run:"
    echo "  code --install-extension $VSIX_FILE"
    echo ""
    print_info "To publish, run this script without --dry-run flag"
else
    print_header "Publishing to Marketplace"
    print_info "Publishing version $CURRENT_VERSION..."

    if [ -n "$VSCE_PAT" ]; then
        if vsce publish -p "$VSCE_PAT"; then
            print_success "Successfully published to VSCode Marketplace!"
        else
            print_error "Publishing failed!"
            exit 1
        fi
    else
        if vsce publish; then
            print_success "Successfully published to VSCode Marketplace!"
        else
            print_error "Publishing failed!"
            exit 1
        fi
    fi

    # Commit version bump if auto-bumped
    if [ -n "$AUTO_BUMP" ]; then
        print_header "Committing Version Bump"
        print_info "Committing package.json changes..."
        git add package.json package-lock.json
        git commit -m "chore: bump version to $CURRENT_VERSION

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

        print_info "Creating git tag v$CURRENT_VERSION..."
        git tag "v$CURRENT_VERSION"

        print_success "Version committed and tagged"
        print_info "Don't forget to push: git push && git push --tags"
    fi

    print_header "Deployment Complete! 🎉"
    echo ""
    print_success "Extension published successfully!"
    print_info "View it at: https://marketplace.visualstudio.com/items?itemName=${PUBLISHER}.yaml-embedded-languages"
    echo ""
    print_info "Next steps:"
    echo "  1. Check the marketplace listing"
    echo "  2. Test installation: code --install-extension ${PUBLISHER}.yaml-embedded-languages"
    if [ -n "$AUTO_BUMP" ]; then
        echo "  3. Push commits and tags: git push && git push --tags"
    fi
    echo ""
fi
