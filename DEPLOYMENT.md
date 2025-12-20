# VSCode Marketplace Deployment Guide

This guide will help you publish the YAML Embedded Languages extension to the Visual Studio Code Marketplace.

## Prerequisites

Before deploying, you need:

1. **A Microsoft/Azure DevOps account**
2. **A VSCode Marketplace publisher account**
3. **A Personal Access Token (PAT)**

## Step-by-Step Setup

### 1. Create a Publisher Account

If you don't have a publisher account yet:

1. Go to the [Visual Studio Marketplace Publisher Management](https://marketplace.visualstudio.com/manage) page
2. Sign in with your Microsoft account
3. Click **"Create publisher"**
4. Fill in the details:
   - **Publisher Name**: A unique ID (lowercase, no spaces, e.g., `tinwonda`)
   - **Display Name**: Human-readable name (e.g., "Tin Trinh")
   - **Description**: Brief description of you/your organization
   - **Email**: Your contact email

5. Click **"Create"**

### 2. Generate a Personal Access Token (PAT)

You need a PAT to publish extensions programmatically:

#### Method 1: Direct Link (Easiest)

1. **Go directly to**: [https://aex.dev.azure.com/me?mkt=en-US](https://aex.dev.azure.com/me?mkt=en-US)
2. Sign in with your Microsoft account
3. Click on **"Personal access tokens"** in the left sidebar
4. You'll see the "Personal Access Tokens" page
5. Continue to "Creating the Token" below

#### Method 2: Through Azure DevOps Portal

1. **Go to**: [https://dev.azure.com](https://dev.azure.com)
2. Sign in with the same Microsoft account you used for the publisher
3. If prompted, create a new organization (use any name, e.g., "tinwonda-org")
4. Click on your **profile icon** (top right corner - it shows your initials/avatar)
5. Click **"Personal access tokens"** from the dropdown menu
6. Continue to "Creating the Token" below

#### Creating the Token

3. Click **"+ New Token"**
4. Configure the token:
   - **Name**: `vsce-publish-token` (or any name you prefer)
   - **Organization**: Select **"All accessible organizations"**
   - **Expiration (UTC)**: Choose an expiration date (recommended: 90 days to 1 year)
   - **Scopes**:
     - Click **"Show all scopes"** at the bottom
     - Scroll down to find **"Marketplace"**
     - Check **"Manage"** under Marketplace
5. Click **"Create"** at the bottom
6. **IMPORTANT**: A dialog will show your token - **copy it immediately**! You won't be able to see it again.
7. Store it safely (you'll use it in Step 4 below)

**Note**: If you don't have an Azure DevOps organization, the system will automatically create one when you create your first PAT.

### 3. Update package.json

Update the `publisher` field in [package.json](package.json):

```json
{
  "publisher": "your-publisher-id"
}
```

Replace `your-publisher-id` with the Publisher Name you created in Step 1.

### 4. Set Up Environment Variable (Optional but Recommended)

To avoid entering your PAT every time, set it as an environment variable:

**On macOS/Linux (add to `~/.zshrc` or `~/.bashrc`):**

```bash
export VSCE_PAT='your-personal-access-token-here'
```

**On Windows (PowerShell):**

```powershell
$env:VSCE_PAT='your-personal-access-token-here'
```

Then reload your terminal:

```bash
# macOS/Linux
source ~/.zshrc  # or ~/.bashrc

# Windows: Close and reopen PowerShell
```

### 5. Install Dependencies

Make sure all dependencies are installed:

```bash
npm install
```

The deployment script will also check and install `vsce` (Visual Studio Code Extension Manager) if needed.

## Deployment

### Quick Deploy

For a standard deployment with automatic patch version bump:

```bash
./deploy.sh --patch
```

### Deployment Options

The `deploy.sh` script supports several options:

#### Test Packaging (Dry Run)

Package the extension without publishing to test if everything builds correctly:

```bash
./deploy.sh --dry-run
```

This will:
- ✓ Clean old builds
- ✓ Install dependencies
- ✓ Run linter
- ✓ Run tests
- ✓ Compile TypeScript
- ✓ Create `.vsix` package
- ✗ Skip publishing

#### Auto Version Bumping

Automatically increment the version number:

```bash
# Patch version: 0.1.9 → 0.1.10 (bug fixes)
./deploy.sh --patch

# Minor version: 0.1.9 → 0.2.0 (new features, backward compatible)
./deploy.sh --minor

# Major version: 0.1.9 → 1.0.0 (breaking changes)
./deploy.sh --major
```

#### Skip Tests

Skip the test suite (useful if tests are slow or you're confident):

```bash
./deploy.sh --skip-tests --patch
```

#### Manual Version Management

If you don't use auto-bumping, update the version manually in `package.json`:

```bash
# Then deploy
./deploy.sh
```

### All Available Options

```
Usage: ./deploy.sh [OPTIONS]

Options:
  --dry-run       Package the extension but don't publish
  --skip-tests    Skip running tests before deployment
  --patch         Auto-bump patch version (0.1.9 -> 0.1.10)
  --minor         Auto-bump minor version (0.1.9 -> 0.2.0)
  --major         Auto-bump major version (0.1.9 -> 1.0.0)
  --help          Show this help message
```

### Example Workflows

**First-time deployment:**

```bash
# 1. Test that everything packages correctly
./deploy.sh --dry-run

# 2. If successful, do the real deployment
./deploy.sh --patch
```

**Regular update with new features:**

```bash
./deploy.sh --minor
```

**Hotfix deployment:**

```bash
./deploy.sh --patch --skip-tests  # Use with caution!
```

## What the Deployment Script Does

The `deploy.sh` script performs these steps in order:

1. **Validation**
   - ✓ Checks if `package.json` exists
   - ✓ Verifies publisher name is set
   - ✓ Checks for VSCE_PAT (warns if missing)
   - ✓ Installs `vsce` if not already installed

2. **Version Management** (if `--patch`, `--minor`, or `--major` used)
   - ✓ Bumps version in `package.json`
   - ✓ Shows old → new version

3. **Clean Build**
   - ✓ Removes old `out/` directory
   - ✓ Removes old `.vsix` files

4. **Dependencies**
   - ✓ Runs `npm install`

5. **Quality Checks**
   - ✓ Runs ESLint
   - ✓ Runs test suite (unless `--skip-tests`)

6. **Build**
   - ✓ Compiles TypeScript
   - ✓ Packages extension as `.vsix`

7. **Publish** (unless `--dry-run`)
   - ✓ Publishes to VSCode Marketplace
   - ✓ Commits version changes (if auto-bumped)
   - ✓ Creates git tag
   - ✓ Shows marketplace URL

## After Deployment

### 1. Verify on Marketplace

Your extension will be available at:

```
https://marketplace.visualstudio.com/items?itemName={publisher}.yaml-embedded-languages
```

It may take a few minutes to appear and up to 1 hour to be fully indexed for search.

### 2. Test Installation

Test installing the published extension:

```bash
code --install-extension {publisher}.yaml-embedded-languages
```

### 3. Push Git Changes

If you used auto-version bumping, push the changes:

```bash
git push
git push --tags
```

### 4. Monitor

- Check the [Publisher Dashboard](https://marketplace.visualstudio.com/manage) for:
  - Install statistics
  - Ratings and reviews
  - Q&A section

## Updating the Extension

When you want to publish updates:

1. Make your code changes
2. Update the version (or use `--patch`/`--minor`/`--major`)
3. Update the [CHANGELOG.md](CHANGELOG.md) (if you have one)
4. Run the deployment script:

```bash
./deploy.sh --patch  # or --minor, or --major
```

## Troubleshooting

### Error: "Publisher name not set"

**Problem**: The `publisher` field in `package.json` is still `"your-publisher-name"`.

**Solution**: Update it with your actual publisher ID from Step 1.

### Error: "Authentication failed"

**Problem**: Your PAT is invalid, expired, or doesn't have the right permissions.

**Solutions**:
1. Regenerate your PAT with "Marketplace > Manage" scope
2. Update the `VSCE_PAT` environment variable
3. Reload your terminal

### Error: "Version X.X.X already exists"

**Problem**: You're trying to publish a version that's already on the marketplace.

**Solution**: Bump the version number:

```bash
./deploy.sh --patch  # or manually update package.json
```

### Linting or Tests Fail

**Problem**: Code quality checks are failing.

**Solutions**:
1. Fix the issues reported by ESLint or tests
2. Or skip tests temporarily (not recommended): `./deploy.sh --skip-tests`

### Package Too Large

**Problem**: The `.vsix` package is too large (marketplace limit is 50MB).

**Solutions**:
1. Add files to `.vscodeignore` to exclude them from the package
2. Remove unnecessary dependencies
3. Optimize assets (images, etc.)

## Advanced: Manual Publishing

If you prefer not to use the deployment script:

```bash
# Install dependencies
npm install

# Compile
npm run compile

# Package
vsce package

# Publish
vsce publish -p YOUR_PAT
```

## Security Best Practices

1. **Never commit your PAT to git**
   - Keep it in environment variables only
   - Add `.env` to `.gitignore` if you use it

2. **Rotate tokens regularly**
   - Set reasonable expiration dates
   - Regenerate if compromised

3. **Use minimal permissions**
   - Only grant "Marketplace > Manage" scope
   - Don't grant unnecessary Azure DevOps permissions

## Resources

- [VSCode Publishing Extensions](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
- [Marketplace Publisher Management](https://marketplace.visualstudio.com/manage)
- [Azure DevOps Personal Access Tokens](https://aex.dev.azure.com/me?mkt=en-US)
- [vsce Documentation](https://github.com/microsoft/vscode-vsce)

## Getting Help

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting) above
2. Review the [vsce documentation](https://github.com/microsoft/vscode-vsce)
3. Check [Stack Overflow](https://stackoverflow.com/questions/tagged/vscode-extension)
4. Open an issue on this repository

---

**Ready to deploy?** Run:

```bash
./deploy.sh --dry-run  # Test first
./deploy.sh --patch    # Then deploy!
```
