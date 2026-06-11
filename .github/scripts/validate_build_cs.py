#!/usr/bin/env python3
"""Build.cs file validator for GitHub Actions CI"""
import re, sys, os

build_cs_file = os.environ.get('BUILD_CS', 'Source/UniversalInteractionSystem/UniversalInteractionSystem.Build.cs')

if not os.path.exists(build_cs_file):
    print(f"::error::Build.cs file not found: {build_cs_file}")
    sys.exit(1)

with open(build_cs_file) as f:
    content = f.read()

# Basic syntax checks
if 'PublicDependencyModuleNames' not in content:
    print('::error::Missing PublicDependencyModuleNames in Build.cs')
    sys.exit(1)

if 'using UnrealBuildTool;' not in content:
    print('::error::Missing using UnrealBuildTool; in Build.cs')
    sys.exit(1)

if 'public class' not in content:
    print('::error::Missing public class definition in Build.cs')
    sys.exit(1)

# Check for common module references
required_modules = ['Core', 'CoreUObject', 'Engine']
for module in required_modules:
    if module not in content:
        print(f"::warning::Common module '{module}' not referenced in Build.cs")

# Check for proper constructor structure
if 'UniversalInteractionSystem' not in content:
    print('::warning::Constructor does not match module name')

print(f"✓ Build.cs validation passed: {build_cs_file}")
print(f"✓ Dependencies found: PublicDependencyModuleNames")
print(f"✓ Using UnrealBuildTool")
sys.exit(0)