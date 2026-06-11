#!/usr/bin/env bash
# FAB Marketplace Review Validation Script
# Validates UE5 plugin submission packages against Epic Games FAB marketplace requirements.
#
# Usage: fab-marketplace-review.sh [VERSION]
#   VERSION - optional, version string to validate (e.g. 1.6.0)
#
# Checks performed:
#   1. .uplugin version consistency (VersionName matches Version int)
#   2. Required .uplugin fields present
#   3. Binary files exist (Binaries/Win64/ not empty)
#   4. No hardcoded secrets, API keys, or PII
#   5. Proper directory structure for FAB submission
#   6. README.md present
#   7. CHANGELOG.md present
#   8. Copyright headers (MountainLabs) in source files
#   9. Zip structure matches Epic requirements
#
# Outputs: review-results.json, review-output.txt

set -euo pipefail

VERSION="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
RESULTS_FILE="$REPO_ROOT/review-results.json"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize results JSON
init_results() {
  local plugin_name="Unknown"
  local uplugin
  uplugin=$(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1)

  if [ -n "$uplugin" ] && [ -f "$uplugin" ]; then
    plugin_name=$(basename "$uplugin" .uplugin)
  fi

  if [ -z "$VERSION" ]; then
    if [ -n "$uplugin" ]; then
      VERSION=$(grep -Po '"VersionName"\s*:\s*"\K[^"]+' "$uplugin" 2>/dev/null || echo "0.0.0")
    fi
  fi

  cat > "$RESULTS_FILE" << EOF
{
  "plugin_name": "$plugin_name",
  "version": "$VERSION",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "checks": []
}
EOF
}

# Add a check result to the JSON
add_check() {
  local name="$1"
  local status="$2"  # pass, fail, warn, skip
  local description="$3"
  local details="${4:-}"
  local remediation="${5:-}"

  local tmp_file
  tmp_file=$(mktemp)

  python3 -c "
import json, sys

results_file = '$RESULTS_FILE'
check = {
    'name': '$name',
    'status': '$status',
    'description': '''$(echo "$description" | sed "s/'/'\\\\''/g")''',
}

details_str = '''$(echo "$details" | sed "s/'/'\\\\''/g")'''
if details_str.strip():
    check['details'] = details_str

remediation_str = '''$(echo "$remediation" | sed "s/'/'\\\\''/g")'''
if remediation_str.strip():
    check['remediation'] = remediation_str

with open(results_file, 'r') as f:
    results = json.load(f)

results['checks'].append(check)

with open(results_file, 'w') as f:
    json.dump(results, f, indent=2)
" 2>/dev/null || true

  rm -f "$tmp_file"

  # Print to terminal
  case "$status" in
    pass) echo -e "  ${GREEN}[PASS]${NC} $name" ;;
    fail) echo -e "  ${RED}[FAIL]${NC} $name - $description" ;;
    warn) echo -e "  ${YELLOW}[WARN]${NC} $name - $description" ;;
    skip) echo -e "  ${CYAN}[SKIP]${NC} $name - $description" ;;
  esac
}

# ============================================================
# CHECK 1: .uplugin version consistency
# ============================================================
check_uplugin_version_consistency() {
  echo "Checking .uplugin version consistency..."
  local uplugin
  uplugin=$(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1)

  if [ -z "$uplugin" ] || [ ! -f "$uplugin" ]; then
    add_check "uplugin-version-consistency" "fail" \
      "No .uplugin file found in repository root" \
      "Searched up to 2 levels deep from $REPO_ROOT" \
      "Create a .uplugin file following Epic Games plugin descriptor format"
    return
  fi

  local version_name version_int
  version_name=$(grep -Po '"VersionName"\s*:\s*"\K[^"]+' "$uplugin" 2>/dev/null || echo "")
  version_int=$(grep -Po '"Version"\s*:\s*\K[0-9]+' "$uplugin" 2>/dev/null || echo "")

  if [ -z "$version_name" ]; then
    add_check "uplugin-version-consistency" "fail" \
      "VersionName field is missing or empty in .uplugin" \
      "File: $uplugin" \
      'Add "VersionName": "X.Y.Z" to the .uplugin file'
    return
  fi

  if [ -z "$version_int" ]; then
    add_check "uplugin-version-consistency" "fail" \
      "Version field is missing or empty in .uplugin" \
      "File: $uplugin" \
      'Add "Version": NNNNN (integer) to the .uplugin file'
    return
  fi

  # Convert VersionName X.Y.Z to integer: X*10000 + Y*100 + Z
  local expected_int
  expected_int=$(echo "$version_name" | awk -F. '{
    major = $1 + 0; minor = $2 + 0; patch = ($3 + 0);
    print major * 10000 + minor * 100 + patch
  }')

  if [ "$version_int" -eq "$expected_int" ]; then
    add_check "uplugin-version-consistency" "pass" \
      "VersionName ($version_name) matches Version ($version_int)"
  else
    add_check "uplugin-version-consistency" "fail" \
      "VersionName ($version_name) does not match Version ($version_int)" \
      "Expected Version integer: $expected_int, got: $version_int" \
      "Update Version to $expected_int to match VersionName $version_name"
  fi
}

# ============================================================
# CHECK 2: Required .uplugin fields
# ============================================================
check_uplugin_required_fields() {
  echo "Checking required .uplugin fields..."
  local uplugin
  uplugin=$(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1)

  if [ -z "$uplugin" ] || [ ! -f "$uplugin" ]; then
    add_check "uplugin-required-fields" "skip" "No .uplugin file found"
    return
  fi

  local missing_fields=""
  local field

  # Required fields per Epic FAB requirements
  for field in "FileVersion" "Version" "VersionName" "FriendlyName" "Category"; do
    if ! grep -q "\"$field\"" "$uplugin" 2>/dev/null; then
      missing_fields="$missing_fields  - $field\n"
    fi
  done

  # Check Modules array is present and non-empty
  if ! grep -q '"Modules"' "$uplugin" 2>/dev/null; then
    missing_fields="$missing_fields  - Modules\n"
  else
    # Verify at least one module entry exists
    local module_count
    module_count=$(python3 -c "
import json, sys
try:
    with open('$uplugin') as f:
        data = json.load(f)
    modules = data.get('Modules', [])
    print(len(modules))
except Exception:
    print(0)
" 2>/dev/null || echo "0")

    if [ "$module_count" -eq 0 ]; then
      missing_fields="$missing_fields  - Modules (array is empty)\n"
    fi
  fi

  if [ -z "$missing_fields" ]; then
    add_check "uplugin-required-fields" "pass" \
      "All required fields present (FileVersion, Version, VersionName, FriendlyName, Category, Modules)"
  else
    add_check "uplugin-required-fields" "fail" \
      "Missing required fields in .uplugin" \
      "Missing:$missing_fields" \
      "Add all required fields to the .uplugin file per Epic Games documentation"
  fi
}

# ============================================================
# CHECK 3: Binary files exist
# ============================================================
check_binary_files() {
  echo "Checking binary files..."
  local bin_dir
  bin_dir=$(find "$REPO_ROOT" -type d -path "*/Binaries/Win64" 2>/dev/null | head -n 1)

  if [ -z "$bin_dir" ]; then
    # This may be expected if we're reviewing source-only (pre-build)
    add_check "binary-files-exist" "warn" \
      "No Binaries/Win64/ directory found" \
      "This is expected if reviewing source-only checkout. Binaries should exist in the release zip." \
      "Ensure the release workflow builds binaries before packaging"
    return
  fi

  local file_count
  file_count=$(find "$bin_dir" -type f 2>/dev/null | wc -l)

  if [ "$file_count" -gt 0 ]; then
    add_check "binary-files-exist" "pass" \
      "Binaries/Win64/ contains $file_count file(s)"
  else
    add_check "binary-files-exist" "fail" \
      "Binaries/Win64/ directory exists but is empty" \
      "Path: $bin_dir" \
      "Build the plugin with UnrealBuildTool before packaging"
  fi
}

# ============================================================
# CHECK 4: No hardcoded secrets or PII
# ============================================================
check_no_secrets() {
  echo "Checking for hardcoded secrets and PII..."
  local findings=""
  local total_findings=0

  # Patterns to search for (case-insensitive)
  # Note: these are grep patterns, not regex
  local patterns=(
    "AKIA[0-9A-Z]{16}"                          # AWS Access Key ID
    "AIza[0-9A-Za-z\-_]{35}"                    # Google API Key
    "ghp_[0-9a-zA-Z]{36}"                       # GitHub Personal Access Token
    "gho_[0-9a-zA-Z]{36}"                       # GitHub OAuth Access Token
    "ghu_[0-9a-zA-Z]{36}"                       # GitHub User-to-Server Token
    "ghs_[0-9a-zA-Z]{36}"                       # GitHub Server-to-Server Token
    "glpat-[0-9a-zA-Z\-]{20}"                   # GitLab Personal Access Token
    "xox[bpas]-[0-9a-zA-Z\-]{10,}"             # Slack tokens
    "sk-[0-9a-zA-Z]{20,}"                       # Generic secret keys (OpenAI etc.)
    "eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\."   # JWT tokens
    "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"  # Private keys
  )

  # Directories to scan
  local scan_dirs=("Source" "Private" "Public")

  local found_in_dir=false
  for dir in "${scan_dirs[@]}"; do
    if [ -d "$REPO_ROOT/$dir" ]; then
      for pattern in "${patterns[@]}"; do
        local matches
        matches=$(grep -rn -E "$pattern" "$REPO_ROOT/$dir" --include="*.h" --include="*.cpp" --include="*.cs" --include="*.py" --include="*.json" --include="*.yaml" --include="*.yml" --include="*.ini" --include="*.cfg" 2>/dev/null | head -5 || true)

        if [ -n "$matches" ]; then
          local match_count
          match_count=$(echo "$matches" | wc -l)
          total_findings=$((total_findings + match_count))
          findings="$findings\n$matches\n"
          found_in_dir=true
        fi
      done
    fi
  done

  if [ "$total_findings" -eq 0 ]; then
    add_check "no-hardcoded-secrets" "pass" \
      "No hardcoded secrets, API keys, or JWT tokens found in source"
  else
    # Truncate details to prevent huge output
    local truncated
    truncated=$(echo -e "$findings" | head -20)
    if [ "$total_findings" -gt 20 ]; then
      truncated="$truncated\n... and $((total_findings - 20)) more findings"
    fi

    add_check "no-hardcoded-secrets" "fail" \
      "Found $total_findings potential secret/key/PII matches in source files" \
      "$truncated" \
      "Move all secrets to environment variables, UE credentials, or encrypted secrets. Never commit secrets to source control."
  fi
}

# ============================================================
# CHECK 5: Proper directory structure
# ============================================================
check_directory_structure() {
  echo "Checking directory structure..."
  local uplugin
  uplugin=$(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1)

  if [ -z "$uplugin" ]; then
    add_check "directory-structure" "skip" "No .uplugin file found, cannot validate structure"
    return
  fi

  local plugin_dir
  plugin_dir=$(dirname "$uplugin")
  local missing=""
  local issues=""

  # Check for Source directory (required for code plugins)
  if [ ! -d "$plugin_dir/Source" ]; then
    missing="$missing  - Source/\n"
  fi

  # Check for Resources directory (optional but recommended)
  if [ ! -d "$plugin_dir/Resources" ]; then
    issues="$issues  - Resources/ directory missing (optional, but recommended for icons)\n"
  fi

  # Check for prohibited files/directories at root level
  local prohibited_found=""
  for item in ".git" ".vs" ".vscode" ".idea" "Binaries" "Intermediate" "DerivedDataCache" ".claude" ".continue" ".development" ".mountains"; do
    if [ -e "$plugin_dir/$item" ]; then
      prohibited_found="$prohibited_found  - $item (should be excluded from submission package)\n"
    fi
  done

  if [ -z "$missing" ] && [ -z "$prohibited_found" ]; then
    local msg="Directory structure is valid"
    if [ -n "$issues" ]; then
      msg="$msg (minor notes: $(echo -e "$issues" | tr '\n' ' '))"
    fi
    add_check "directory-structure" "pass" "$msg"
  else
    local detail=""
    if [ -n "$missing" ]; then
      detail="Missing required:$missing"
    fi
    if [ -n "$prohibited_found" ]; then
      detail="${detail}Should be excluded from zip:$prohibited_found"
    fi
    add_check "directory-structure" "fail" \
      "Directory structure issues detected" \
      "$detail" \
      "Ensure the plugin has proper UE5 plugin directory layout. Exclude build artifacts and IDE files from the submission zip."
  fi
}

# ============================================================
# CHECK 6: README.md present
# ============================================================
check_readme() {
  echo "Checking README.md..."
  local readme
  readme=$(find "$REPO_ROOT" -maxdepth 1 -name "README.md" -type f 2>/dev/null | head -n 1)

  if [ -z "$readme" ]; then
    add_check "readme-present" "fail" \
      "No README.md found in repository root" \
      "Epic FAB requires documentation for marketplace submissions" \
      "Create a README.md with installation instructions, features, and usage examples"
    return
  fi

  local size
  size=$(wc -c < "$readme")
  local line_count
  line_count=$(wc -l < "$readme")

  if [ "$line_count" -lt 10 ]; then
    add_check "readme-present" "warn" \
      "README.md exists but is very short ($line_count lines, ${size} bytes)" \
      "Marketplace listings benefit from comprehensive documentation" \
      "Expand README.md with installation steps, features, screenshots, and API overview"
  else
    add_check "readme-present" "pass" \
      "README.md present ($line_count lines, ${size} bytes)"
  fi
}

# ============================================================
# CHECK 7: CHANGELOG.md present
# ============================================================
check_changelog() {
  echo "Checking CHANGELOG.md..."
  local changelog
  changelog=$(find "$REPO_ROOT" -maxdepth 1 -name "CHANGELOG.md" -type f 2>/dev/null | head -n 1)

  if [ -z "$changelog" ]; then
    add_check "changelog-present" "fail" \
      "No CHANGELOG.md found in repository root" \
      "FAB marketplace reviews expect version history documentation" \
      "Create a CHANGELOG.md following Keep-a-Changelog format"
    return
  fi

  local line_count
  line_count=$(wc -l < "$changelog")

  if [ "$line_count" -lt 5 ]; then
    add_check "changelog-present" "warn" \
      "CHANGELOG.md exists but is very short ($line_count lines)" \
      "Consider adding more detailed version history" \
      "Document each version's changes following Keep-a-Changelog format"
  else
    add_check "changelog-present" "pass" \
      "CHANGELOG.md present ($line_count lines)"
  fi
}

# ============================================================
# CHECK 8: Copyright headers
# ============================================================
check_copyright_headers() {
  echo "Checking copyright headers in source files..."
  local source_dir="$REPO_ROOT/Source"

  if [ ! -d "$source_dir" ]; then
    add_check "copyright-headers" "skip" "No Source/ directory found"
    return
  fi

  # Count source files
  local total_files
  total_files=$(find "$source_dir" -type f \( -name "*.h" -o -name "*.cpp" -o -name "*.cs" \) 2>/dev/null | wc -l)

  if [ "$total_files" -eq 0 ]; then
    add_check "copyright-headers" "skip" "No source files (.h, .cpp, .cs) found in Source/"
    return
  fi

  # Count files with MountainLabs copyright
  local copyrighted_files
  copyrighted_files=$(grep -rl -i "MountainLabs\|Mountain Labs\|MountainLabs UG" "$source_dir" --include="*.h" --include="*.cpp" --include="*.cs" 2>/dev/null | wc -l)

  # Count files with any copyright notice
  local any_copyright
  any_copyright=$(grep -rl -i "copyright\|©" "$source_dir" --include="*.h" --include="*.cpp" --include="*.cs" 2>/dev/null | wc -l)

  local missing_copyright=$((total_files - any_copyright))
  local wrong_copyright=$((any_copyright - copyrighted_files))

  if [ "$missing_copyright" -eq 0 ] && [ "$wrong_copyright" -eq 0 ]; then
    add_check "copyright-headers" "pass" \
      "All $total_files source files have MountainLabs copyright headers"
  elif [ "$missing_copyright" -gt 0 ]; then
    add_check "copyright-headers" "fail" \
      "$missing_copyright of $total_files source files lack copyright headers" \
      "Files with no copyright: $missing_copyright" \
      "Add MountainLabs UG copyright headers to all source files"
  elif [ "$wrong_copyright" -gt 0 ]; then
    add_check "copyright-headers" "warn" \
      "$wrong_copyright of $total_files source files have copyright headers but do not mention MountainLabs" \
      "These may reference a previous company name (e.g., Seven-Mountains)" \
      "Update copyright headers to reference MountainLabs UG"
  fi
}

# ============================================================
# CHECK 9: Zip structure validation
# ============================================================
check_zip_structure() {
  echo "Checking zip structure requirements..."
  local uplugin
  uplugin=$(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1)

  if [ -z "$uplugin" ]; then
    add_check "zip-structure" "skip" "No .uplugin file found"
    return
  fi

  local plugin_dir
  plugin_dir=$(dirname "$uplugin")
  local plugin_name
  plugin_name=$(basename "$uplugin" .uplugin)

  # Epic FAB requires the zip to contain the plugin folder at the root
  # i.e., extracting the zip should give: PluginName/Source/..., PluginName/PluginName.uplugin, etc.

  local issues=""

  # Check that .uplugin is at the expected depth
  if [ "$(dirname "$plugin_dir")" != "$REPO_ROOT" ]; then
    issues="$issues  - .uplugin is not directly under repo root (at $(dirname "$plugin_dir"))\n"
  fi

  # Check for Files to exclude from zip
  local exclude_patterns=(".git" ".github" ".vs" ".vscode" ".idea" ".claude" ".continue" ".mountains"
    "Binaries" "Intermediate" "DerivedDataCache" "Saved" ".development"
    "*.sln" "*.suo" "*.user" "*.sdf" "*.db" "*.log" "*.tmp")

  local found_excludes=""
  for pattern in "${exclude_patterns[@]}"; do
    if [ -e "$plugin_dir/$pattern" ] 2>/dev/null; then
      found_excludes="$found_excludes  - $pattern\n"
    elif find "$plugin_dir" -maxdepth 1 -name "$pattern" -print -quit 2>/dev/null | grep -q .; then
      found_excludes="$found_excludes  - $pattern (glob match)\n"
    fi
  done

  if [ -z "$issues" ] && [ -z "$found_excludes" ]; then
    add_check "zip-structure" "pass" \
      "Repository structure is compatible with Epic FAB zip requirements"
  else
    local detail=""
    if [ -n "$issues" ]; then
      detail="Structure issues:$issues"
    fi
    if [ -n "$found_excludes" ]; then
      detail="${detail}Items that must be excluded from submission zip:$found_excludes"
    fi
    add_check "zip-structure" "warn" \
      "Zip packaging may need adjustments for FAB compliance" \
      "$detail" \
      "Ensure the release workflow excludes all build artifacts, IDE files, and internal directories from the submission zip"
  fi
}

# ============================================================
# MAIN
# ============================================================
main() {
  echo "============================================"
  echo " FAB Marketplace Review Agent"
  echo " Plugin: $(find "$REPO_ROOT" -maxdepth 2 -name "*.uplugin" -type f 2>/dev/null | head -n 1 | xargs basename 2>/dev/null || echo "Unknown")"
  echo " Version: ${VERSION:-auto-detect}"
  echo " Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo "============================================"
  echo ""

  init_results

  echo "--- Running validation checks ---"
  echo ""

  check_uplugin_version_consistency
  check_uplugin_required_fields
  check_binary_files
  check_no_secrets
  check_directory_structure
  check_readme
  check_changelog
  check_copyright_headers
  check_zip_structure

  echo ""
  echo "--- Review complete ---"
  echo ""

  # Summary
  python3 -c "
import json
with open('$RESULTS_FILE') as f:
    results = json.load(f)

checks = results['checks']
passed = [c for c in checks if c['status'] == 'pass']
failed = [c for c in checks if c['status'] == 'fail']
warnings = [c for c in checks if c['status'] == 'warn']
skipped = [c for c in checks if c['status'] == 'skip']

total = len(checks)
overall = 'PASS' if not failed else 'FAIL'

print(f'Summary: {len(passed)}/{total} passed, {len(failed)} failed, {len(warnings)} warnings, {len(skipped)} skipped')
print(f'Overall: {overall}')

if failed:
    print()
    print('Failed checks:')
    for c in failed:
        print(f'  - {c[\"name\"]}: {c[\"description\"]}')
" 2>/dev/null

  # Exit with failure if any checks failed
  python3 -c "
import json
with open('$RESULTS_FILE') as f:
    results = json.load(f)
failed = [c for c in results['checks'] if c['status'] == 'fail']
exit(1 if failed else 0)
"
}

main "$@"
