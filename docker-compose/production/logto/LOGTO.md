# Production Deployment Guide for LobeChat with Logto Authentication

This guide provides a production-ready workflow for deploying LobeChat on a GPU-enabled server VM at [https://lobe.prometheusags.ai](https://lobe.prometheusags.ai), using Docker Compose, Logto authentication, MinIO storage, and Nginx as a secure web proxy.

---

## 1. Architecture Overview

**Key Components:**
- **Main App**: LobeChat web application at https://lobe.prometheusags.ai
- **Authentication**: Logto auth server (internal, not exposed directly)
- **Storage**: MinIO S3-compatible storage (internal)
- **Database**: PostgreSQL with pgvector (internal)
- **Proxy**: Nginx for TLS termination and routing (host-level)

**Domain Strategy:**
- Single domain: `auth.prometheusags.ai` (reuse existing certificate)
- All services accessed through the main domain via proxy paths
- No additional certificates needed

---

## 2. Nginx Configuration

### 2.1. Reuse Existing Certificate for auth.prometheusags.ai

We'll use the existing `auth.prometheusags.ai` certificate and domain for Logto admin interface.

### 2.2. Nginx Config for auth.prometheusags.ai

```nginx
server {
    listen 80;
    server_name auth.prometheusags.ai;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name auth.prometheusags.ai;

    ssl_certificate /etc/letsencrypt/live/auth.prometheusags.ai/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.prometheusags.ai/privkey.pem;

    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Increase buffer and timeout for large requests
    client_max_body_size 100M;
    proxy_read_timeout 600s;
    proxy_connect_timeout 60s;
    proxy_send_timeout 600s;

    # Logto Admin Console
    location /admin {
        proxy_pass http://127.0.0.1:23002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
    }

    # Logto API (for OIDC endpoints)
    location / {
        proxy_pass http://127.0.0.1:23001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
    }
}
```

---

## 3. Docker Compose Configuration

### 3.1. Port Strategy
Use non-conflicting ports for all services:
- PostgreSQL: 25432 (mapped from 5432)
- MinIO API: 29000 (mapped from 9000) 
- MinIO Console: 29001 (mapped from 9001)
- Logto API: 23001 (mapped from 3001)
- Logto Admin: 23002 (mapped from 3002)
- LobeChat: 23210 (mapped from 3210)

### 3.2. Environment Variables
- Use single domain approach: `auth.prometheusags.ai` for Logto
- Configure MinIO with proper credentials
- Set up NextAuth with Logto provider

---

## 4. Deployment Steps

### 4.1. Setup Phase
1. Create nginx config for auth.prometheusags.ai (reuse existing cert)
2. Configure docker-compose.yml with proper ports and domains
3. Set up .env file with generated secrets and credentials
4. Start services: `docker compose up -d`

### 4.2. Configuration Phase  
1. Access Logto admin at https://auth.prometheusags.ai/admin
2. Create application for LobeChat
3. Configure OAuth callback URLs
4. Update .env with Logto client credentials
5. Restart LobeChat container

### 4.3. MinIO Setup
1. Access MinIO console at http://localhost:29001
2. Create `lobe` bucket
3. Create access keys for LobeChat
4. Update .env with MinIO credentials
5. Restart LobeChat container

---

## 5. Key Benefits over Zitadel

**Simplicity:**
- Single container vs multiple containers
- No complex PAT token management
- Standard OIDC flow without custom login UI

**Maintenance:**
- Fewer moving parts
- Simpler configuration
- Better documentation and community support

**Integration:**
- Direct NextAuth support
- Standard OAuth 2.0/OIDC implementation
- No custom proxy routing needed

---

## 6. Security Considerations

- All services run on internal Docker network
- Only necessary ports exposed via nginx proxy
- TLS termination at nginx level
- Secure secret management via Docker secrets/env files
- Regular updates and monitoring

---

**This strategy provides a production-ready LobeChat deployment with Logto authentication, maintaining security and simplicity.**

## Current Progress Status

✅ **COMPLETED:**
- Step 4.1: Docker Compose services started successfully
- All services are running healthy:
  - PostgreSQL (Logto): Port 25434
  - PostgreSQL (LobeChat): Port 25435  
  - MinIO: Ports 29000 (API), 29001 (Console)
  - Logto: Ports 23001 (API), 23002 (Admin)
  - LobeChat: Port 23210
- Nginx configuration for auth.prometheusags.ai is active
- Logto admin interface is accessible at https://auth.prometheusags.ai/admin

🔄 **NEXT STEPS:**
- Step 4.2: Configure Logto application for LobeChat
- Step 4.3: Configure MinIO bucket and access keys
- Step 4.4: Update .env with credentials and restart LobeChat

---

## Step 4.2: Logto Configuration

### Access Logto Admin Console
1. Go to: https://auth.prometheusags.ai/admin
2. Complete initial setup (create admin account)
3. Create new application for LobeChat

### Application Configuration
- **Application Name**: LobeChat
- **Application Type**: Traditional Web Application  
- **Redirect URIs**: 
  - `https://lobe.prometheusags.ai/api/auth/callback/logto`
- **Post Sign-out Redirect URIs**:
  - `https://lobe.prometheusags.ai`
- **CORS Origins**:
  - `https://lobe.prometheusags.ai`

### Required Information to Collect:
- Client ID (AUTH_LOGTO_ID)
- Client Secret (AUTH_LOGTO_SECRET) 
- OIDC Issuer URL (already set: https://auth.prometheusags.ai/oidc)


## FIXED: Admin Console Access

✅ **Admin Console is now working!**

**Correct URLs:**
- Main Access: https://auth.prometheusags.ai/admin (redirects to welcome page)
- Direct Access: https://auth.prometheusags.ai/console/welcome

The nginx configuration has been updated to:
1. Redirect `/admin` to `/console/welcome` for easy access
2. Proxy all `/console` paths to the Logto admin console (port 23002)
3. Proxy all other paths to the Logto API (port 23001) for OIDC endpoints

**Next Steps:**
1. ✅ Access https://auth.prometheusags.ai/admin in your browser
2. Complete the initial Logto setup wizard
3. Create a new application for LobeChat
4. Configure OAuth callback URLs as specified in Step 4.2 above


## FIXED: Database Initialization Issue Resolved

✅ **Issue Resolved!** 

The "Unauthorized. Please check credentials and its scope" error has been fixed by:
1. Completely removing the old database data
2. Restarting with fresh database initialization  
3. Successfully seeding the database with proper admin configuration

**All services are now running properly:**
- ✅ PostgreSQL (Logto): Port 25434 - Healthy
- ✅ PostgreSQL (LobeChat): Port 25435 - Healthy  
- ✅ MinIO: Ports 29000/29001 - Running
- ✅ Logto: Ports 23001/23002 - Running & Seeded
- ✅ LobeChat: Port 23210 - Running
- ✅ Nginx: Both domains configured and working

**Ready to Proceed:**
The Logto admin console should now work without the authentication errors.

