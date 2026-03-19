#!/bin/bash
# generate_configs.sh — Substitute environment variables into XML/properties templates
#
# Run this before invoking build_deployer_archive.sh or deploy_archive.sh.
# All variables below must be set in the environment (export or CI/CD variable groups).
#
# Usage:
#   export WM_PROJECT_NAME="MyProject"
#   export WM_PACKAGES="PackageA,PackageB"
#   ... (see full variable list in each template file)
#   ./generate_configs.sh
#
# Output: instantiated files written to /opt/wmprojects/config/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMPLATE_DIR="$REPO_ROOT/config"
OUTPUT_DIR="${WM_CONFIG_OUTPUT_DIR:-/opt/wmprojects/config}"

mkdir -p "$OUTPUT_DIR"

echo "=== Generating webMethods Deployer config files ==="
echo "    Template dir : $TEMPLATE_DIR"
echo "    Output dir   : $OUTPUT_DIR"

# ------------------------------------------------------------------
# Build WM_PACKAGES_XML from comma-separated WM_PACKAGES list
# e.g. WM_PACKAGES="Processing,ArchiveUtils"
# produces:
#   <ISPackage name="Processing"/>
#   <ISPackage name="ArchiveUtils"/>
# ------------------------------------------------------------------
WM_PACKAGES_XML=""
IFS=',' read -ra PKG_ARRAY <<< "${WM_PACKAGES:-}"
for pkg in "${PKG_ARRAY[@]}"; do
    pkg="$(echo "$pkg" | xargs)"  # trim whitespace
    WM_PACKAGES_XML="${WM_PACKAGES_XML}        <ISPackage name=\"${pkg}\"/>\n"
done
export WM_PACKAGES_XML

# Defaults for optional deployment flags
export WM_SIMULATE="${WM_SIMULATE:-false}"
export WM_RESTART_AFTER="${WM_RESTART_AFTER:-false}"
export WM_CONTINUE_ON_ERROR="${WM_CONTINUE_ON_ERROR:-false}"

# ------------------------------------------------------------------
# Substitute all environment variables in each template file
# ------------------------------------------------------------------
for template in buildProject.xml deployProject.xml build.properties; do
    src="$TEMPLATE_DIR/$template"
    dst="$OUTPUT_DIR/$template"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: Template not found: $src" >&2
        exit 1
    fi
    envsubst < "$src" > "$dst"
    echo "    Generated: $dst"
done

echo "=== Config generation complete ==="
