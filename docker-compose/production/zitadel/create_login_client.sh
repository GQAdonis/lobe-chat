#!/bin/bash

# This script helps create the login client service user and PAT for Zitadel
# You need to run this after logging into the Zitadel console as admin

ZITADEL_URL="https://auth.prometheusags.ai"
PAT_FILE="/usr/local/src/lobe-chat/docker-compose/production/zitadel/login-client.pat"

echo "=== Zitadel Login Client Setup ==="
echo "Please follow these steps:"
echo ""
echo "1. Open your browser and go to: ${ZITADEL_URL}/ui/console"
echo "2. Login with: root / Password1!"
echo "3. Go to 'Users' -> 'Create New User' -> 'Service User'"
echo "4. Fill in:"
echo "   - Username: login-client"
echo "   - Name: Automatically Initialized IAM Login Client"
echo "   - Click 'Create'"
echo ""
echo "5. After creating the user, go to the user details"
echo "6. Click on 'Personal Access Tokens' tab"
echo "7. Click 'New' to create a PAT"
echo "8. Set expiration date: 2029-01-01"
echo "9. Copy the generated token"
echo ""
echo "10. Run this command to save the token:"
echo "    echo 'YOUR_COPIED_TOKEN_HERE' > ${PAT_FILE}"
echo ""
echo "11. Restart the zitadel-login container:"
echo "    docker restart lobe-zitadel-login"
echo ""
echo "=== Alternative: API Method ==="
echo "If you prefer to use API calls, you can get an admin PAT first and use curl commands."
echo "But the console method above is easier for one-time setup."
