#!/bin/bash

ZITADEL_URL="https://auth.prometheusags.ai"
ADMIN_USERNAME="root"
ADMIN_PASSWORD="Password1!"

echo "=== Creating Zitadel Login Client via API ==="

# Step 1: Get admin session token
echo "1. Getting admin session token..."
LOGIN_RESPONSE=$(curl -s -k -X POST "${ZITADEL_URL}/v2/users/me/_login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'$ADMIN_USERNAME'",
    "password": "'$ADMIN_PASSWORD'"
  }')

echo "Login response: $LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q "sessionToken"; then
    SESSION_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
    echo "✓ Got session token: ${SESSION_TOKEN:0:20}..."
else
    echo "✗ Failed to get session token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

# Step 2: Create service user (machine user)
echo ""
echo "2. Creating service user 'login-client'..."
USER_RESPONSE=$(curl -s -k -X POST "${ZITADEL_URL}/v2/organizations/me/users" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -d '{
    "username": "login-client",
    "machine": {
      "name": "Automatically Initialized IAM Login Client",
      "description": "Service user for zitadel-login container"
    }
  }')

echo "User creation response: $USER_RESPONSE"

if echo "$USER_RESPONSE" | grep -q "userId"; then
    USER_ID=$(echo "$USER_RESPONSE" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
    echo "✓ Created user with ID: $USER_ID"
else
    echo "✗ Failed to create user"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

# Step 3: Create PAT for the service user
echo ""
echo "3. Creating Personal Access Token..."
PAT_RESPONSE=$(curl -s -k -X POST "${ZITADEL_URL}/v2/organizations/me/users/${USER_ID}/personal_access_tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -d '{
    "expirationDate": "2029-01-01T00:00:00Z"
  }')

echo "PAT creation response: $PAT_RESPONSE"

if echo "$PAT_RESPONSE" | grep -q "token"; then
    PAT_TOKEN=$(echo "$PAT_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "✓ Created PAT token: ${PAT_TOKEN:0:20}..."
    
    # Save to file
    echo "$PAT_TOKEN" > /usr/local/src/lobe-chat/docker-compose/production/zitadel/login-client.pat
    echo "✓ Saved PAT to login-client.pat"
    
    # Restart login container
    echo ""
    echo "4. Restarting zitadel-login container..."
    docker restart lobe-zitadel-login
    echo "✓ Container restarted"
    
    echo ""
    echo "=== Setup Complete! ==="
    echo "You should now be able to log in at: ${ZITADEL_URL}/ui/console"
    
else
    echo "✗ Failed to create PAT"
    echo "Response: $PAT_RESPONSE"
    exit 1
fi
