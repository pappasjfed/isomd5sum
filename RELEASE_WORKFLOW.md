# Release Workflow Guide

This document explains how the automated release system works for the isomd5sum project.

## Overview

The project has three types of releases:

1. **Stable Releases** - Created from version tags
2. **Pre-releases (Beta) from develop** - Automatically created from develop branch (Windows only)
3. **Pre-releases (Beta) from dev** - Automatically created from dev branch via PRs (Linux + Windows x64 builds published to GitHub Releases)

## Stable Releases

### How to Create

```bash
# On master branch, after merging changes
git tag v1.0.0
git push origin v1.0.0
```

### What Happens

- Workflow builds Windows executables (MSVC + MinGW)
- Runs all tests
- Creates GitHub Release with version tag (e.g., `v1.0.0`)
- Marked as stable release
- Includes:
  - `isomd5sum-1.0.0-windows-x64-msvc.zip`
  - `isomd5sum-1.0.0-windows-x64-mingw.zip`
  - `checksums.txt`

## Pre-releases (Beta)

### Beta from Dev Branch (Recommended)

The `dev` branch is the primary branch for beta releases and includes both Linux and Windows builds.

#### How to Create

1. Create a pull request targeting the `dev` branch
2. Once PR is reviewed and merged to `dev`, beta release is automatically created

```bash
# Create a feature branch
git checkout -b feature/my-feature dev

# Make changes, commit
git add .
git commit -m "Add new feature"

# Push and create PR to dev branch
git push origin feature/my-feature
# Create PR on GitHub targeting 'dev' branch

# After PR is merged, beta is automatically released
```

#### What Happens

- Workflow triggers on PR to `dev` - runs tests only
- When PR is merged (push to `dev`):
  - Builds Linux x64 executables (Fedora 39)
  - Builds Windows x64 executables (MSVC)
  - Runs all tests
  - Creates GitHub Pre-release with timestamp-based tag
  - Publishes x64 zip artifacts to GitHub Releases
  - Marked with ⚠️ pre-release warning
- Version format: `beta-YYYYMMDD-HHMMSS-{short-commit-sha}`
  - Example: `beta-20260130-161500-abc1234`

#### Includes

- `isomd5sum-beta-...-linux-x64.tar.gz` - Linux build (tarball)
- `isomd5sum-beta-...-linux-x64.zip` - Linux build (zip)
- `isomd5sum-beta-...-windows-x64.zip` - Windows build (zip)
- `checksums.txt` with SHA256 hashes
- Build information (commit SHA, timestamp)
- Warning about development build status
- All artifacts available via GitHub Releases

### Beta from Develop Branch (Legacy)

The `develop` branch continues to work for Windows-only pre-releases.

### How to Create

Simply push to the develop branch:

```bash
git push origin develop
```

### What Happens

- Workflow automatically triggers on every push to develop
- Builds Windows executables (MSVC + MinGW)
- Runs all tests
- Creates GitHub Pre-release with timestamp-based tag
- Marked with ⚠️ pre-release warning
- Version format: `beta-YYYYMMDD-HHMMSS-{short-commit-sha}`
  - Example: `beta-20260129-041752-9ef1eba`

### Includes

- `isomd5sum-beta-...-windows-x64-msvc.zip`
- `isomd5sum-beta-...-windows-x64-mingw.zip`
- `checksums.txt` with SHA256 hashes
- Build information (commit SHA, timestamp)
- Warning about development build status

## Workflow Triggers

The workflow runs on:

1. **Push to master** - Builds and tests, no release
2. **Push to dev** - Builds, tests, and creates pre-release with x64 zip artifacts
3. **Pull requests to dev** - Builds and tests only (no release)
4. **Push to develop** - Builds, tests, and creates Windows-only pre-release (legacy)
5. **Version tag (v*)** - Builds, tests, and creates stable release
6. **Pull requests to master** - Builds and tests only
7. **Manual dispatch** - Can trigger manually from Actions tab

## Artifact Retention

- **Build artifacts**: Retained for 30 days in GitHub Actions
- **Releases**: Permanent until manually deleted
- **Pre-releases**: Can be cleaned up periodically

## Best Practices

### For Development

1. Work on feature branches
2. Merge to develop for testing
3. Automatic pre-release created
4. Test the pre-release builds

### For Stable Release

1. Ensure develop is stable
2. Merge develop to master
3. Create version tag
4. Push tag to trigger release

## Permissions

The workflow needs:

- `contents: read` - For building and testing
- `contents: write` - For creating releases (only release jobs)

## Cleanup

### Removing Old Pre-releases

Pre-releases can accumulate. To clean up:

1. Go to repository Releases page
2. Click on pre-release to delete
3. Delete release and its tag

Or use GitHub CLI:

```bash
# List pre-releases
gh release list --repo pappasjfed/isomd5sum

# Delete specific pre-release
gh release delete beta-20260129-041752-9ef1eba --repo pappasjfed/isomd5sum --yes
```

## Troubleshooting

### Pre-release not created

Check:
- Push was to develop branch
- Workflow completed successfully
- Workflow has `contents: write` permission

### Stable release not created

Check:
- Tag starts with 'v'
- Tag was pushed (not just created locally)
- Workflow completed successfully

## Examples

### Creating v1.0.0 Release

```bash
git checkout master
git pull origin master
git tag v1.0.0
git push origin v1.0.0
```

### Triggering Pre-release

```bash
git checkout develop
# Make changes, commit
git push origin develop
# Pre-release created automatically
```
