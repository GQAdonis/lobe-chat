#!/bin/bash

PAT_FILE="/usr/local/src/lobe-chat/docker-compose/production/zitadel/login-client.pat"
ZITADEL_URL="https://auth.prometheusags.ai"

echo "=== Testing Zitadel Login Setup ==="
echo ""

# Check if PAT file exists and has content
if [ -f "$PAT_FILE" ]; then
    echo "✓ PAT file exists: $PAT_FILE"
    PAT_CONTENT=$(cat "$PAT_FILE" | tr -d '\n\r ')
    if [ "$PAT_CONTENT" != "DUMMY_TOKEN_REPLACE_WITH_REAL" ] && [ -n "$PAT_CONTENT" ]; then
        echo "✓ PAT file has valid content (not dummy token)"
    else
        echo "✗ PAT file still contains dummy token or is empty"
        exit 1
    fi
else
    echo "✗ PAT file not found: $PAT_FILE"
    exit 1
fi

# Check zitadel-login container status
echo ""
echo "Checking zitadel-login container..."
if docker ps | grep -q "lobe-zitadel-login"; then
    echo "✓ zitadel-login container is running"
else
    echo "✗ zitadel-login container is not running"
    echo "Try: docker restart lobe-zitadel-login"
    exit 1
fi

# Check login container logs for errors
echo ""
echo "Checking login container logs..."
LOGS=$(docker logs lobe-zitadel-login 2>&1 | tail -5)
if echo "$LOGS" | grep -q "Ready in"; then
    echo "✓ zitadel-login container started successfully"
else
    echo "⚠ Check zitadel-login container logs:"
    echo "$LOGS"
fi

# Test login URL
echo ""
echo "Testing login URL..."
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "${ZITADEL_URL}/ui/v2/login/login?authRequest=test")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "400" ]; then
    echo "✓ Login URL responding (HTTP $HTTP_CODE)"
    echo "  Note: 400 is expected for invalid authRequest, 200 means it's working"
else
    echo "✗ Login URL returning HTTP $HTTP_CODE (expected 200 or 400)"
fi

# Test main console
echo ""
echo "Testing main console..."
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "${ZITADEL_URL}/ui/console")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Main console responding (HTTP $HTTP_CODE)"
else
    echo "✗ Main console returning HTTP $HTTP_CODE"
fi

echo ""
echo "=== Test Summary ==="
echo "If all checks pass, your Zitadel login setup is working correctly!"
echo "You can now proceed to configure OAuth clients for LobeChat."
