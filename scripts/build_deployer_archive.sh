#!/bin/bash
# build_deployer_archive.sh — Run webMethods Deployer build phase
#
# Generates the Deployer archive (.zip) from a repository-based source
# (ABE output, Git checkout, or local package export) using projectautomator.sh.
#
# Prerequisites:
#   - generate_configs.sh has already been run (config files are substituted)
#   - WM_HOME is set and webMethods Deployer is installed
#   - Java is available under $WM_HOME/jvm/jvm
#
# Usage (standalone):
#   export WM_HOME=/webMethods
#   export WM_CONFIG_DIR=/opt/wmprojects/config
#   export WM_LOG_DIR=/opt/wmprojects/logs
#   ./build_deployer_archive.sh
#
# In Azure DevOps / Jenkins: called as a Bash task step after generate_configs.sh.

set -euo pipefail

WM_HOME="${WM_HOME:-/webMethods}"
DEPLOYER_HOME="$WM_HOME/Deployer"
JAVA_HOME="${JAVA_HOME:-$WM_HOME/jvm/jvm}"
WM_CONFIG_DIR="${WM_CONFIG_DIR:-/opt/wmprojects/config}"
WM_LOG_DIR="${WM_LOG_DIR:-/opt/wmprojects/logs}"

BUILD_PROPERTIES="$WM_CONFIG_DIR/build.properties"
BUILD_LOG="$WM_LOG_DIR/build.log"

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

echo "=== Starting webMethods Deployer Build ==="
echo "    WM_HOME         : $WM_HOME"
echo "    build.properties: $BUILD_PROPERTIES"
echo "    build.log       : $BUILD_LOG"

# Validate pre-conditions
if [[ ! -f "$BUILD_PROPERTIES" ]]; then
    echo "ERROR: build.properties not found at $BUILD_PROPERTIES" >&2
    echo "       Run generate_configs.sh first." >&2
    exit 1
fi

if [[ ! -x "$DEPLOYER_HOME/bin/projectautomator.sh" ]]; then
    echo "ERROR: projectautomator.sh not found or not executable at $DEPLOYER_HOME/bin" >&2
    exit 1
fi

java -version 2>&1 | head -1

mkdir -p "$WM_LOG_DIR"

cd "$DEPLOYER_HOME/bin"

./projectautomator.sh \
    -buildProperties "$BUILD_PROPERTIES" \
    -log "$BUILD_LOG"

# Verify success
if grep -q "BUILD SUCCESSFUL" "$BUILD_LOG"; then
    echo "=== Build Successful ==="
else
    echo "ERROR: Build failed — 'BUILD SUCCESSFUL' not found in log." >&2
    echo "--- Last 30 lines of $BUILD_LOG ---" >&2
    tail -30 "$BUILD_LOG" >&2
    exit 1
fi
