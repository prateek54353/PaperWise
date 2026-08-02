#!/usr/bin/env python3
"""
Version bump script for PaperWise Flutter app.
Updates pubspec.yaml and generates local.properties with version info.
"""

import re
import sys
import argparse
from pathlib import Path


def parse_version(version_string):
    """Parse version string like '2.4.0+18' into (major, minor, patch, build_number)"""
    match = re.match(r'(\d+)\.(\d+)\.(\d+)\+(\d+)', version_string)
    if not match:
        raise ValueError(f"Invalid version format: {version_string}")
    return tuple(map(int, match.groups()))


def format_version(major, minor, patch, build_number):
    """Format version components into 'major.minor.patch+build_number'"""
    return f"{major}.{minor}.{patch}+{build_number}"


def update_pubspec(version):
    """Update version in pubspec.yaml"""
    pubspec_path = Path("pubspec.yaml")
    if not pubspec_path.exists():
        raise FileNotFoundError("pubspec.yaml not found")
    
    content = pubspec_path.read_text()
    content = re.sub(
        r'version: \d+\.\d+\.\d+\+\d+',
        f'version: {version}',
        content
    )
    pubspec_path.write_text(content)
    print(f"✓ Updated pubspec.yaml to {version}")


def generate_local_properties(version):
    """Generate local.properties with Flutter version info"""
    version_name, build_number = version.split('+')
    
    content = f"""flutter.versionName={version_name}
flutter.versionCode={build_number}
"""
    
    local_props_path = Path("android/local.properties")
    local_props_path.parent.mkdir(parents=True, exist_ok=True)
    local_props_path.write_text(content)
    print(f"✓ Generated android/local.properties")


def bump_version_part(major, minor, patch, build_number, part):
    """Bump the specified version part"""
    if part == "major":
        return (major + 1, 0, 0, 1)
    elif part == "minor":
        return (major, minor + 1, 0, 1)
    elif part == "patch":
        return (major, minor, patch + 1, 1)
    elif part == "build":
        return (major, minor, patch, build_number + 1)
    else:
        raise ValueError(f"Invalid version part: {part}")


def main():
    parser = argparse.ArgumentParser(description="Bump version for PaperWise Flutter app")
    parser.add_argument(
        "part",
        choices=["major", "minor", "patch", "build"],
        help="Which part of the version to increment"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes"
    )
    
    args = parser.parse_args()
    
    # Read current version from pubspec.yaml
    pubspec_path = Path("pubspec.yaml")
    if not pubspec_path.exists():
        print("Error: pubspec.yaml not found")
        sys.exit(1)
    
    content = pubspec_path.read_text()
    match = re.search(r'version: (\d+\.\d+\.\d+\+\d+)', content)
    if not match:
        print("Error: Could not find version in pubspec.yaml")
        sys.exit(1)
    
    current_version = match.group(1)
    major, minor, patch, build_number = parse_version(current_version)
    
    # Bump the specified part
    new_major, new_minor, new_patch, new_build = bump_version_part(
        major, minor, patch, build_number, args.part
    )
    new_version = format_version(new_major, new_minor, new_patch, new_build)
    
    print(f"Current version: {current_version}")
    print(f"New version: {new_version}")
    
    if args.dry_run:
        print("Dry run - no changes made")
        return
    
    # Update files
    try:
        update_pubspec(new_version)
        generate_local_properties(new_version)
        print(f"\n✓ Successfully bumped version to {new_version}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
