# Sandpack Configuration for LobeChat

## Overview

LobeChat has been configured to use a custom Sandpack bundler server running on this system instead of the default CodeSandbox bundler. This provides better performance and control over code execution.

## Configuration Details

### 1. Static Browser Server
- **Service**: `static-browser-server-prod` Docker container
- **Internal Port**: 4324
- **Public URL**: `https://preview.prometheusags.ai`
- **Wildcard Support**: `*.preview.prometheusags.ai` (for sandboxed environments)

### 2. Nginx Configuration
- **Config File**: `/etc/nginx/sites-available/static-browser-server`
- **Features**:
  - HTTPS with wildcard SSL certificate
  - CORS headers enabled for cross-origin requests
  - WebSocket support for real-time features
  - Health check endpoint at `/health`

### 3. Environment Variable
- **Variable**: `NEXT_PUBLIC_SANDPACK_BUNDLER_URL=https://preview.prometheusags.ai`
- **Location**: `/usr/local/src/lobe-chat/docker-compose/production/logto/.env`
- **Purpose**: Configures Sandpack to use the local bundler instead of CodeSandbox

### 4. Code Modification
- **File**: `/usr/local/src/lobe-chat/src/features/Portal/Artifacts/Body/Renderer/React/index.tsx`
- **Changes**: Added environment variable support for custom bundler URL
- **Backup**: Available as `index.tsx.backup`

## How It Works

1. When users create React artifacts in LobeChat, the Sandpack component loads
2. The component reads `NEXT_PUBLIC_SANDPACK_BUNDLER_URL` environment variable
3. If set, it uses the custom bundler URL instead of the default CodeSandbox bundler
4. Code is processed locally on the static browser server at `preview.prometheusags.ai`
5. Sandboxed environments are created under `*.preview.prometheusags.ai` subdomains

## Benefits

- **Performance**: Local bundling is faster than remote CodeSandbox service
- **Privacy**: Code doesn't leave your infrastructure
- **Reliability**: No dependency on external CodeSandbox availability
- **Customization**: Full control over the bundling environment

## Testing

To verify the configuration:

1. Test static browser server:
   ```bash
   curl -I https://preview.prometheusags.ai/
   ```

2. Check environment variable is loaded:
   ```bash
   docker exec lobe-chat env | grep SANDPACK
   ```

3. Test code artifact creation in LobeChat web interface

## Troubleshooting

### Service Restart
Remember to use full restart for environment changes:
```bash
cd /usr/local/src/lobe-chat/docker-compose/production/logto
docker compose down && docker compose up -d
```

### Check Static Server
Verify the static browser server container is running:
```bash
docker ps | grep static-browser-server
```

### Check Nginx Configuration
Test nginx configuration:
```bash
sudo nginx -t
sudo systemctl reload nginx
```
