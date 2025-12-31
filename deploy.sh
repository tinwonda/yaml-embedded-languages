#!/bin/bash

# VSCode Marketplace & Open VSX Deployment Script
# This script helps you deploy the YAML Embedded Languages extension to both marketplaces

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
MANUAL_VERSION=""
PUBLISH_VSCODE=true
PUBLISH_OPENVSX=true

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
        --version)
            MANUAL_VERSION="$2"
            shift 2
            ;;
        --vscode-only)
            PUBLISH_VSCODE=true
            PUBLISH_OPENVSX=false
            shift
            ;;
        --openvsx-only)
            PUBLISH_VSCODE=false
            PUBLISH_OPENVSX=true
            shift
            ;;
        --help)
            echo "VSCode Marketplace & Open VSX Deployment Script"
            echo ""
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Package the extension but don't publish"
            echo "  --skip-tests    Skip running tests before deployment"
            echo "  --patch         Auto-bump patch version (0.1.9 -> 0.1.10)"
            echo "  --minor         Auto-bump minor version (0.1.9 -> 0.2.0)"
            echo "  --major         Auto-bump major version (0.1.9 -> 1.0.0)"
            echo "  --version X.Y.Z Set a specific version (e.g., 1.2.3)"
            echo "  --vscode-only   Publish only to VSCode Marketplace"
            echo "  --openvsx-only  Publish only to Open VSX Registry"
            echo "  --help          Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  VSCE_PAT        Personal Access Token for VSCode Marketplace"
            echo "  OVSX_PAT        Personal Access Token for Open VSX Registry"
            echo ""
            echo "Examples:"
            echo "  ./deploy.sh --dry-run              # Test packaging without publishing"
            echo "  ./deploy.sh --patch                # Bump patch and publish to both"
            echo "  ./deploy.sh --minor --skip-tests   # Bump minor, skip tests, publish to both"
            echo "  ./deploy.sh --version 2.0.0        # Set version to 2.0.0 and publish to both"
            echo "  ./deploy.sh --vscode-only --patch  # Publish only to VSCode Marketplace"
            echo "  ./deploy.sh --openvsx-only --patch # Publish only to Open VSX"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "YAML Embedded Languages - Multi-Marketplace Deployment"

# Show which marketplaces will be targeted
if [ "$PUBLISH_VSCODE" == "true" ] && [ "$PUBLISH_OPENVSX" == "true" ]; then
    print_info "Target: VSCode Marketplace + Open VSX Registry"
elif [ "$PUBLISH_VSCODE" == "true" ]; then
    print_info "Target: VSCode Marketplace only"
elif [ "$PUBLISH_OPENVSX" == "true" ]; then
    print_info "Target: Open VSX Registry only"
fi

# Check if running in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found! Please run this script from the project root."
    exit 1
fi

# Check if vsce is installed (if needed)
if [ "$PUBLISH_VSCODE" == "true" ]; then
    if ! command -v vsce &> /dev/null; then
        print_warning "vsce (Visual Studio Code Extension Manager) is not installed globally."
        print_info "Installing vsce..."
        npm install -g @vscode/vsce
        print_success "vsce installed successfully"
    fi
fi

# Check if ovsx is installed (if needed)
if [ "$PUBLISH_OPENVSX" == "true" ]; then
    if ! command -v ovsx &> /dev/null; then
        print_warning "ovsx (Open VSX CLI) is not installed globally."
        print_info "Installing ovsx..."
        npm install -g ovsx
        print_success "ovsx installed successfully"
    fi
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

# Check for conflicting version options
if [ -n "$MANUAL_VERSION" ] && [ -n "$AUTO_BUMP" ]; then
    print_error "Cannot use both --version and --patch/--minor/--major options together!"
    exit 1
fi

# Set manual version if specified
if [ -n "$MANUAL_VERSION" ]; then
    print_info "Setting version to $MANUAL_VERSION..."
    npm version $MANUAL_VERSION --no-git-tag-version --allow-same-version
    NEW_VERSION=$(node -p "require('./package.json').version")
    print_success "Version set: $CURRENT_VERSION → $NEW_VERSION"
    CURRENT_VERSION=$NEW_VERSION
# Auto-bump version if specified
elif [ -n "$AUTO_BUMP" ]; then
    print_info "Auto-bumping $AUTO_BUMP version..."
    npm version $AUTO_BUMP --no-git-tag-version
    NEW_VERSION=$(node -p "require('./package.json').version")
    print_success "Version bumped: $CURRENT_VERSION → $NEW_VERSION"
    CURRENT_VERSION=$NEW_VERSION
fi

# Check if tokens are set
TOKENS_OK=true

if [ "$PUBLISH_VSCODE" == "true" ]; then
    if [ -z "$VSCE_PAT" ]; then
        print_warning "VSCE_PAT environment variable not set."
        echo ""
        echo "To get a Personal Access Token for VSCode Marketplace:"
        echo "1. Go to https://aex.dev.azure.com/me?mkt=en-US"
        echo "2. Create a new token with 'Marketplace > Manage' scope"
        echo "3. Set it as VSCE_PAT environment variable: export VSCE_PAT='your-token'"
        echo ""
        TOKENS_OK=false
    else
        print_success "VSCE_PAT token found"
    fi
fi

if [ "$PUBLISH_OPENVSX" == "true" ]; then
    if [ -z "$OVSX_PAT" ]; then
        print_warning "OVSX_PAT environment variable not set."
        echo ""
        echo "To get a Personal Access Token for Open VSX:"
        echo "1. Go to https://open-vsx.org/user-settings/tokens"
        echo "2. Create a new Access Token"
        echo "3. Set it as OVSX_PAT environment variable: export OVSX_PAT='your-token'"
        echo ""
        TOKENS_OK=false
    else
        print_success "OVSX_PAT token found"
    fi

    # Important namespace warning for Open VSX
    echo ""
    print_warning "IMPORTANT: Open VSX Namespace Requirement"
    echo ""
    echo "Before publishing to Open VSX for the first time, you MUST:"
    echo ""
    echo "1. Sign in to Open VSX at https://open-vsx.org"
    echo "   (Use GitHub, Eclipse, or other OAuth providers)"
    echo ""
    echo "2. Create a namespace at https://open-vsx.org/user-settings/namespaces"
    echo "   - Click 'Create a new namespace'"
    echo "   - Namespace name must match your publisher: '$PUBLISHER'"
    echo "   - Use the EXACT same name (case-sensitive)"
    echo ""
    echo "3. Common issues if you get 'Invalid access token' error:"
    echo "   - Namespace doesn't exist or doesn't match publisher name"
    echo "   - Not signed in when creating the token"
    echo "   - Token created before the namespace was created"
    echo "   - Using wrong account (check you're signed in as the namespace owner)"
    echo ""
    echo "If you've already created the namespace '$PUBLISHER', you can ignore this."
    echo ""
fi

if [ "$TOKENS_OK" == "false" ] && [ "$DRY_RUN" == "false" ]; then
    echo ""
    print_warning "Some tokens are missing. You'll be prompted during publish or the publish may fail."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
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
    VSIX_FILE="yaml-code-injection-highlight-${CURRENT_VERSION}.vsix"
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
    PUBLISH_SUCCESS=true
    PUBLISHED_TO=()

    # Publish to VSCode Marketplace
    if [ "$PUBLISH_VSCODE" == "true" ]; then
        print_header "Publishing to VSCode Marketplace"
        print_info "Publishing version $CURRENT_VERSION to VSCode Marketplace..."

        if [ -n "$VSCE_PAT" ]; then
            if vsce publish -p "$VSCE_PAT"; then
                print_success "Successfully published to VSCode Marketplace!"
                PUBLISHED_TO+=("VSCode Marketplace")
            else
                print_error "Publishing to VSCode Marketplace failed!"
                PUBLISH_SUCCESS=false
            fi
        else
            if vsce publish; then
                print_success "Successfully published to VSCode Marketplace!"
                PUBLISHED_TO+=("VSCode Marketplace")
            else
                print_error "Publishing to VSCode Marketplace failed!"
                PUBLISH_SUCCESS=false
            fi
        fi
    fi

    # Publish to Open VSX
    if [ "$PUBLISH_OPENVSX" == "true" ]; then
        print_header "Publishing to Open VSX Registry"
        print_info "Publishing version $CURRENT_VERSION to Open VSX..."

        if [ -n "$OVSX_PAT" ]; then
            if ovsx publish -p "$OVSX_PAT"; then
                print_success "Successfully published to Open VSX Registry!"
                PUBLISHED_TO+=("Open VSX Registry")
            else
                print_error "Publishing to Open VSX Registry failed!"
                echo ""
                print_warning "Troubleshooting Tips:"
                echo ""
                echo "If you see 'Invalid access token' error:"
                echo "  1. Make sure namespace '$PUBLISHER' exists at:"
                echo "     https://open-vsx.org/user-settings/namespaces"
                echo ""
                echo "  2. Verify you're signed in to the account that owns the namespace"
                echo ""
                echo "  3. Create a fresh token AFTER creating the namespace:"
                echo "     https://open-vsx.org/user-settings/tokens"
                echo ""
                echo "  4. Update your token: export OVSX_PAT='your-new-token'"
                echo ""
                echo "  5. Verify the namespace name matches EXACTLY (case-sensitive):"
                echo "     Namespace: $PUBLISHER (must be this exact spelling)"
                echo ""
                PUBLISH_SUCCESS=false
            fi
        else
            if ovsx publish; then
                print_success "Successfully published to Open VSX Registry!"
                PUBLISHED_TO+=("Open VSX Registry")
            else
                print_error "Publishing to Open VSX Registry failed!"
                echo ""
                print_warning "Troubleshooting Tips:"
                echo ""
                echo "If you see 'Invalid access token' error:"
                echo "  1. Make sure namespace '$PUBLISHER' exists at:"
                echo "     https://open-vsx.org/user-settings/namespaces"
                echo ""
                echo "  2. Verify you're signed in to the account that owns the namespace"
                echo ""
                echo "  3. Create a fresh token AFTER creating the namespace:"
                echo "     https://open-vsx.org/user-settings/tokens"
                echo ""
                echo "  4. Update your token: export OVSX_PAT='your-new-token'"
                echo ""
                echo "  5. Verify the namespace name matches EXACTLY (case-sensitive):"
                echo "     Namespace: $PUBLISHER (must be this exact spelling)"
                echo ""
                PUBLISH_SUCCESS=false
            fi
        fi
    fi

    # Commit version bump if auto-bumped or manually set
    if [ "$PUBLISH_SUCCESS" == "true" ] && ([ -n "$AUTO_BUMP" ] || [ -n "$MANUAL_VERSION" ]); then
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

    # Print final status
    if [ "$PUBLISH_SUCCESS" == "true" ]; then
        print_header "Deployment Complete! 🎉"
        echo ""
        print_success "Extension published successfully to: ${PUBLISHED_TO[*]}"
        echo ""

        if [[ " ${PUBLISHED_TO[@]} " =~ " VSCode Marketplace " ]]; then
            print_info "VSCode Marketplace: https://marketplace.visualstudio.com/items?itemName=${PUBLISHER}.yaml-code-injection-highlight"
        fi

        if [[ " ${PUBLISHED_TO[@]} " =~ " Open VSX Registry " ]]; then
            print_info "Open VSX Registry: https://open-vsx.org/extension/${PUBLISHER}/yaml-code-injection-highlight"
        fi

        echo ""
        print_info "Next steps:"
        echo "  1. Check the marketplace listing(s)"
        echo "  2. Test installation: code --install-extension ${PUBLISHER}.yaml-code-injection-highlight"
        if [ -n "$AUTO_BUMP" ] || [ -n "$MANUAL_VERSION" ]; then
            echo "  3. Push commits and tags: git push && git push --tags"
        fi
        echo ""
    else
        print_header "Deployment Failed"
        print_error "Some publications failed. Please check the errors above."
        exit 1
    fi
fi
