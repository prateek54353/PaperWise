# Release Automation Guide

This document explains how to automate releases with automatic version increases for both Android (APK) and iOS (unsigned IPA) builds.

## Overview

The release automation system consists of:

1. **Version bump script** (`scripts/bump_version.py`) - Manually bump versions locally
2. **Full release workflow** (`.github/workflows/full-release.yml`) - Automated builds for both platforms on tag push
3. **Updated individual workflows** - Separate Android and iOS workflows with version sync

## How It Works

### Version Format

The project uses semantic versioning with build numbers:
- Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Example: `2.2.0+16` (version 2.2.0, build number 16)

### Automatic Version Sync on Tags

When you push a version tag (e.g., `v2.3.0`), the workflow automatically:

1. Extracts the version from the tag (e.g., `2.3.0`)
2. Increments the build number from `pubspec.yaml`
3. Updates `pubspec.yaml` with the new version + build number
4. Generates `android/local.properties` with version info
5. Commits these changes back to the repository
6. Builds and uploads both Android APKs and iOS unsigned IPA

## Usage

### Option 1: Create a Release Tag (Recommended)

Create and push a version tag to trigger the full release workflow:

```bash
# Create and push a new version tag
git tag v2.3.0
git push origin v2.3.0
```

This will:
- Bump version to `2.3.0+17` (assuming current is `2.2.0+16`)
- Build Android APKs (split per ABI)
- Build iOS unsigned IPA
- Upload all artifacts to GitHub Release as draft

### Option 2: Manual Version Bump

Use the version bump script for local development or pre-release testing:

```bash
# Bump major version (2.2.0+16 -> 3.0.0+1)
python scripts/bump_version.py major

# Bump minor version (2.2.0+16 -> 2.3.0+1)
python scripts/bump_version.py minor

# Bump patch version (2.2.0+16 -> 2.2.1+1)
python scripts/bump_version.py patch

# Bump build number only (2.2.0+16 -> 2.2.0+17)
python scripts/bump_version.py build

# Dry run to see what would change
python scripts/bump_version.py patch --dry-run
```

## Workflows

### Full Release Workflow (`.github/workflows/full-release.yml`)

**Trigger:** Push tags matching `v*`

**Jobs:**
1. `version-sync` - Updates version info and commits changes
2. `build-android` - Builds signed APKs (split per ABI)
3. `build-ios` - Builds unsigned IPA

**Artifacts:**
- Android: `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`
- iOS: `Paperwise-unsigned-{version}.ipa`

This is the single workflow that handles both Android and iOS releases automatically when you push a version tag.

## GitHub Secrets Required

For Android signed builds, configure these secrets in your repository:

- `KEYSTORE_BASE64` - Base64-encoded keystore file
- `KEY_ALIAS` - Key alias
- `KEY_PASSWORD` - Key password
- `STORE_PASSWORD` - Keystore password

To encode your keystore:
```bash
base64 -i android/app/release-keystore.jks | pbcopy  # macOS
base64 -w 0 android/app/release-keystore.jks        # Linux
```

## Local Development Signing

For local release builds, you can configure signing in `android/local.properties`:

1. Copy the example file:
   ```bash
   cp android/local.properties.example android/local.properties
   ```

2. Fill in your keystore details:
   ```properties
   storeFile=/path/to/your/release-keystore.jks
   storePassword=your_keystore_password
   keyAlias=your_key_alias
   keyPassword=your_key_password
   ```

3. Build signed release locally:
   ```bash
   flutter build apk --release
   ```

The signing configuration supports both:
- **Environment variables** (for CI/CD)
- **local.properties** (for local development)

## Signing Configuration Details

### How Signing Works

The build process automatically:
1. Checks for signing credentials in environment variables (CI) or local.properties (local)
2. If credentials are found, signs the release APK with your keystore
3. If no credentials are found, builds an unsigned APK (with a warning)
4. Enables code shrinking and resource minification for release builds
5. Verifies APK signing after build when credentials are available

### Release Build Features

- **Code shrinking**: Enabled with `isMinifyEnabled = true`
- **Resource shrinking**: Enabled with `isShrinkResources = true`
- **Debug builds**: Have `.debug` suffix and `-debug` version suffix
- **Signed verification**: Automatic signing verification after build

### Generating a Keystore

If you don't have a keystore yet:

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

Keep your keystore file and passwords secure - never commit them to version control.

## Release Process

### Standard Release Process

1. **Bump version locally** (optional, for testing):
   ```bash
   python scripts/bump_version.py patch
   git add pubspec.yaml android/local.properties
   git commit -m "chore: bump version to 2.2.1"
   git push
   ```

2. **Create release tag**:
   ```bash
   git tag v2.2.1
   git push origin v2.2.1
   ```

3. **Wait for workflow completion** - Check the Actions tab

4. **Review and publish release** - Go to Releases, edit the draft, and publish

### Hotfix Process

For quick hotfixes without changing major/minor version:

```bash
# Bump patch version
python scripts/bump_version.py patch
git add pubspec.yaml android/local.properties
git commit -m "hotfix: version bump"
git push

# Create tag
git tag v2.2.1
git push origin v2.2.1
```

## Files Modified by Automation

The automated workflows modify these files:

1. **`pubspec.yaml`** - Updates the `version:` field
2. **`android/local.properties`** - Creates/updates with Flutter version info
   - `flutter.versionName` - The semantic version (e.g., `2.3.0`)
   - `flutter.versionCode` - The build number (e.g., `17`)

iOS version info is automatically derived from these files via the Flutter build system.

## Troubleshooting

### Version sync commits fail

If the version sync job fails to push changes:
- Check that the GitHub Actions bot has write permissions
- Ensure branch protection rules allow automated commits
- Check that `[skip ci]` is working if you have CI checks

### Android build fails

- Verify all required secrets are set
- Check that the keystore encoding is correct
- Ensure the Flutter version in the workflow matches your project

### iOS build fails

- Ensure you're using the correct Flutter version
- Check that CocoaPods dependencies are up to date
- Verify the `--no-codesign` flag is working for unsigned builds

## Best Practices

1. **Always test locally** before creating release tags
2. **Use semantic versioning** consistently
3. **Keep the build number incrementing** - it's used for app store submissions
4. **Review the draft release** before publishing
5. **Tag after merging** to main, not before
6. **Document changes** in the release notes

## Version Strategy

- **Major version** (X.0.0): Breaking changes, major features
- **Minor version** (x.Y.0): New features, backward compatible
- **Patch version** (x.y.Z): Bug fixes, small improvements
- **Build number**: Auto-incremented on each release

## Future Enhancements

Potential improvements to consider:

- Add changelog generation from commit messages
- Implement automatic release notes from PR descriptions
- Add Slack/Discord notifications on releases
- Implement beta/alpha release channels
- Add automated app store submission (requires additional setup)
