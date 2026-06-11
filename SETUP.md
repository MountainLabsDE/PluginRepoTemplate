# Setup Guide

This guide will help you set up the Plugin Repository Template for your UE5 plugin project.

## Prerequisites

Before using this template, ensure you have:

1. **GitHub Organization Account** with access to create repositories
2. **Shared Self-Hosted Runner** with labels: `self-hosted`, `Windows`
3. **Unreal Engine 5** installed on your development machine
4. **Basic knowledge** of Git, GitHub, and Unreal Engine development

## Quick Setup

### Step 1: Create Repository from Template

1. Navigate to: `https://github.com/MountainLabsDE/PluginRepoTemplate`
2. Click **"Use this template"** → **"Create a new repository"**
3. Choose your organization (MountainLabsDE)
4. Name your plugin repository (e.g., `MyPlugin`)
5. Set as **Public** or **Private** as needed
6. Click **"Create repository"**

### Step 2: Branch Configuration

Your new repository will be created with:
- **`main`** branch (production/stable releases)
- **No `development` branch** (create it manually)

Create the development branch:
```bash
git checkout -b development main
git push origin development
```

### Step 3: Configure Branch Protection

1. Go to **Settings** → **Branches**
2. Add branch protection for `main`:
   - ✅ Require pull request before merging
   - ✅ Require approvals (1 reviewer)
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date

### Step 4: Update Plugin Configuration

1. Rename `YourPluginName.uplugin` to match your plugin name
2. Edit the `.uplugin` file:
   - Update `"FriendlyName"` to your plugin name
   - Update `"Description"` with plugin description
   - Update `"CreatedBy"` with your GitHub username

### Step 5: Create Initial Development

1. Create your plugin source code in the `Source/` directory
2. Make your first commit:
   ```bash
   git add .
   git commit -m "feat: initial plugin structure"
   git push origin development
   ```

## Detailed Setup

### Self-Hosted Runner Configuration

Your organization uses a shared runner (TIM-PC) with these labels:
- `self-hosted` - Indicates it's not a GitHub-hosted runner
- `Windows` - Specifies the platform
- `X64` - Architecture
- `mountainlabs` - Organization-specific label

#### Verify Runner Access

1. Check your repository runner status:
   ```bash
   # Using GitHub CLI
   gh api repos/MountainLabsDE/YOUR_REPO/actions/runners
   ```

2. Ensure your organization has access to the shared runner

#### Runner Requirements

The shared runner should have:
- **Windows 10/11** or **Windows Server 2019/2022**
- **PowerShell 5.1+**
- **Git** installed and configured
- **Unreal Engine 5** (for plugin builds)

### Secrets Configuration

#### No Secrets Required for Basic Operation

This template works out of the box with:
- ✅ Automatic versioning (uses `GITHUB_TOKEN` automatically)
- ✅ GitHub releases (uses `GITHUB_TOKEN` automatically)
- ✅ Validation workflows

#### Optional Secrets for Enhanced Features

If you want additional features, add these secrets in **Settings → Secrets and variables → Actions**:

```bash
# Google Drive Uploads (Optional)
GOOGLE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
GOOGLE_DRIVE_FOLDER_ID='your-folder-id'

# MinIO/S3 Storage (Optional)
MINIO_ACCESS_KEY='your-access-key'
MINIO_SECRET_KEY='your-secret-key'
MINIO_BUCKET_NAME='plugin-releases'
MINIO_ENDPOINT='minio.yourdomain.com'

# Wiki.js Documentation (Optional)
WIKIJS_INSTANCE_URL='https://wiki.yourdomain.com'
WIKIJS_API_KEY='your-wikijs-api-key'
WIKIJS_DOCUMENTATION_PATH='ue5-plugins'
```

### Workflow Testing

#### Test Development Workflow

1. Create a test commit on development:
   ```bash
   git checkout development
   echo "// Test file" >> Source/YourPlugin/YourPlugin.cpp
   git add .
   git commit -m "test: development workflow test"
   git push origin development
   ```

2. Check GitHub Actions tab to see:
   - ✅ Auto-versioning runs
   - ✅ Version increments to `0.0.1-dev`
   - ✅ Plugin file updated automatically

#### Test Main Workflow

1. Create a pull request from development to main:
   ```bash
   gh pr create --base main --head development --title "Test PR" --body "Testing main workflow"
   ```

2. Check GitHub Actions tab to see:
   - ✅ Validation runs
   - ✅ Version format checked
   - ✅ Version progression validated

#### Test Release Workflow

1. Merge approved PR to main
2. Check GitHub Actions tab to see:
   - ✅ Auto-versioning runs based on commit type
   - ✅ Version increments (feature → minor, fix → patch)
   - ✅ GitHub release created
   - ✅ UE5 plugin builds triggered
   - ✅ Build artifacts uploaded to release

## Branch Strategy in Practice

### Development Workflow

```bash
# Start new feature
git checkout development
git checkout -b feature/interaction-system

# Make changes
# ... develop feature ...

# Commit with conventional message
git add .
git commit -m "feat: add ray-cast interaction system"

# Push and test
git push origin feature/interaction-system

# Create PR to development (if using team workflow)
gh pr create --base development --head feature/interaction-system

# Merge to development
# Auto-versioning: 0.0.0 → 0.0.1-dev → 0.0.2-dev → ...
```

### Production Workflow

```bash
# Feature is ready for production
git checkout development
git checkout -b release/interaction-system

# Update changelog
echo "## [1.1.0] - YYYY-MM-DD" >> CHANGELOG.md
echo "### Added" >> CHANGELOG.md
echo "- Ray-cast interaction system" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: update changelog for release"

# Create PR to main
git push origin release/interaction-system
gh pr create --base main --head release/interaction-system --title "Release interaction system"

# Get approval and merge
# Auto-versioning: 1.0.0 → 1.1.0 (feature detected)
# GitHub release created automatically
# UE5 plugin builds triggered
```

### Emergency Fix Workflow

```bash
# Fix critical bug in main
git checkout main
git checkout -b hotfix/critical-bug

# Fix bug
# ... implement fix ...

# Commit with conventional message
git add .
git commit -m "fix: resolve crash in interaction system"

# Push and create PR
git push origin hotfix/critical-bug
gh pr create --base main --head hotfix/critical-bug --title "Hotfix critical bug"

# Merge immediately
# Auto-versioning: 1.1.0 → 1.1.1 (fix detected)
# GitHub release created automatically
```

## Troubleshooting

### Workflow Fails with "No Runner Available"

**Problem**: Workflows fail with runner not found error.

**Solution**: 
1. Verify your organization has access to shared runner TIM-PC
2. Check runner is online in **Settings → Actions → Runners**
3. Ensure runner has labels: `self-hosted`, `Windows`

### Version Not Incrementing

**Problem**: Commits don't trigger version increments.

**Solution**:
1. Check commit message uses conventional format:
   - `feat:` → minor increment on main
   - `fix:` → patch increment
   - `perf:` → patch increment
   - Any other → no increment
2. Ensure workflow has permission to push commits
3. Check workflow logs for errors

### Release Builds Fail

**Problem**: UE5 plugin builds fail during release.

**Solution**:
1. Verify Unreal Engine 5 is installed on runner
2. Check plugin structure is correct (Source/, Config/, Resources/)
3. Ensure .uplugin file is valid JSON
4. Review build logs in GitHub Actions

## Next Steps

After basic setup:

1. **Customize workflows** for your specific needs
2. **Add testing workflows** if you have automated tests
3. **Configure additional deployment targets** (Google Drive, MinIO)
4. **Set up Wiki.js integration** for automatic documentation
5. **Create custom actions** for repetitive tasks
6. **Set up branch protection rules** for your team

## Support

For issues and questions:
- **GitHub Issues**: Create an issue in the template repository
- **Documentation**: Check README.md and workflow comments
- **Workflow Status**: Check the Actions tab in your repository

---

**Template Version**: 1.0.0  
**Last Updated**: 2024  
**Maintained by**: MountainLabsDE