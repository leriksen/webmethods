#!/bin/bash
# post_deploy_check.sh — Verify Integration Server health after deployment
#
# Calls the wm.server/ping service on the target IS and fails if it does not
# return an "ok" response. Use this as the final step of the deploy stage.
#
# Usage:
#   ./post_deploy_check.sh <host> <port> <user> <password>
#
# Or via environment variables:
#   export WM_TARGET_HOST=qa-is.company.com
#   export WM_TARGET_PORT=5555
#   export WM_TARGET_USER=Administrator
#   export WM_TARGET_PASSWORD=secret
#   ./post_deploy_check.sh
#
# Exit codes:
#   0 — IS is responding correctly
#   1 — IS ping failed (deployment may need investigation)

set -euo pipefail

HOST="${1:-${WM_TARGET_HOST:-}}"
PORT="${2:-${WM_TARGET_PORT:-5555}}"
USER="${3:-${WM_TARGET_USER:-}}"
PASS="${4:-${WM_TARGET_PASSWORD:-}}"
MAX_RETRIES="${WM_PING_RETRIES:-5}"
RETRY_DELAY="${WM_PING_DELAY:-10}"

if [[ -z "$HOST" || -z "$USER" || -z "$PASS" ]]; then
    echo "ERROR: WM_TARGET_HOST, WM_TARGET_USER, and WM_TARGET_PASSWORD must be set." >&2
    exit 1
fi

PING_URL="http://${HOST}:${PORT}/invoke/wm.server/ping"

echo "=== Post-Deployment Health Check ==="
echo "    Target: $PING_URL"

attempt=0
while (( attempt < MAX_RETRIES )); do
    (( attempt++ )) || true
    echo "    Attempt $attempt/$MAX_RETRIES..."

    response=$(curl -s --max-time 15 -u "${USER}:${PASS}" "$PING_URL" 2>&1 || true)

    if echo "$response" | grep -q "ok"; then
        echo "=== Target IS is responding correctly. ==="
        exit 0
    fi

    echo "    Ping returned: $response"
    if (( attempt < MAX_RETRIES )); then
        echo "    Retrying in ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
    fi
done

echo "ERROR: Target IS ping failed after $MAX_RETRIES attempts." >&2
echo "       Check deployment logs and IS status at ${HOST}:${PORT}" >&2
exit 1
