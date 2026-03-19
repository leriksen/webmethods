#!/bin/bash
# deploy_archive.sh — Run webMethods Deployer deployment phase
#
# Deploys the archive built by build_deployer_archive.sh to a target
# Integration Server using deployer.sh.
#
# Prerequisites:
#   - generate_configs.sh has already been run (config files are substituted)
#   - build_deployer_archive.sh has successfully produced the archive
#   - WM_HOME is set and webMethods Deployer is installed
#
# Usage (standalone):
#   export WM_HOME=/webMethods
#   export WM_CONFIG_DIR=/opt/wmprojects/config
#   export WM_LOG_DIR=/opt/wmprojects/logs
#   ./deploy_archive.sh
#
# In Azure DevOps / Jenkins: called as a Bash task step after build.

set -euo pipefail

WM_HOME="${WM_HOME:-/webMethods}"
DEPLOYER_HOME="$WM_HOME/Deployer"
JAVA_HOME="${JAVA_HOME:-$WM_HOME/jvm/jvm}"
WM_CONFIG_DIR="${WM_CONFIG_DIR:-/opt/wmprojects/config}"
WM_LOG_DIR="${WM_LOG_DIR:-/opt/wmprojects/logs}"

DEPLOY_XML="$WM_CONFIG_DIR/deployProject.xml"
DEPLOY_LOG="$WM_LOG_DIR/deploy.log"

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

echo "=== Starting webMethods Deployer Deployment ==="
echo "    WM_HOME         : $WM_HOME"
echo "    deployProject   : $DEPLOY_XML"
echo "    deploy.log      : $DEPLOY_LOG"

# Validate pre-conditions
if [[ ! -f "$DEPLOY_XML" ]]; then
    echo "ERROR: deployProject.xml not found at $DEPLOY_XML" >&2
    echo "       Run generate_configs.sh first." >&2
    exit 1
fi

if [[ ! -x "$DEPLOYER_HOME/bin/deployer.sh" ]]; then
    echo "ERROR: deployer.sh not found or not executable at $DEPLOYER_HOME/bin" >&2
    exit 1
fi

mkdir -p "$WM_LOG_DIR"

cd "$DEPLOYER_HOME/bin"

./deployer.sh \
    -input "$DEPLOY_XML" \
    -log "$DEPLOY_LOG"

# Verify success
if grep -q "Deployment completed successfully" "$DEPLOY_LOG"; then
    echo "=== Deployment Successful ==="
else
    echo "ERROR: Deployment failed — 'Deployment completed successfully' not found in log." >&2
    echo "--- ERROR lines from $DEPLOY_LOG ---" >&2
    grep "ERROR" "$DEPLOY_LOG" || true
    echo "--- Last 30 lines of $DEPLOY_LOG ---" >&2
    tail -30 "$DEPLOY_LOG" >&2
    exit 1
fi
