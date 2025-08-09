# File Upload Configuration for LobeChat

## Configuration Summary

### 1. MinIO S3 Storage
- **Container**: `lobe-minio`
- **Internal Port**: 9000 (API), 9001 (Console)
- **External Ports**: 29000 (API), 29001 (Console)
- **Bucket**: `lobe`
- **Access**: Public read/write
- **Credentials**: 
  - User: `lobe_minio_user`
  - Password: `lobe_minio_password_123`

### 2. Nginx Proxy Configuration
- **Path**: `https://lobe.prometheusags.ai/s3/`
- **Proxies to**: `http://127.0.0.1:29000/`
- **Features**:
  - CORS headers enabled
  - 100MB max file size
  - OPTIONS request handling

### 3. Environment Variables
```
S3_ACCESS_KEY_ID=lobe_minio_user
S3_SECRET_ACCESS_KEY=lobe_minio_password_123
S3_ENDPOINT=http://minio:9000
S3_BUCKET=lobe
S3_PUBLIC_DOMAIN=https://lobe.prometheusags.ai/s3
S3_ENABLE_PATH_STYLE=1
```

### 4. Key Points
- Files are uploaded through the nginx proxy at `/s3/` path
- No direct external access to MinIO ports
- Bucket is configured with public access for file serving
- Path-style access is enabled for S3 compatibility

### 5. Testing
Test S3 proxy access:
```bash
curl -I https://lobe.prometheusags.ai/s3/lobe/
```

Should return HTTP 200 with CORS headers.

## Troubleshooting

### Service Restart
Always use full restart for environment changes:
```bash
cd /usr/local/src/lobe-chat/docker-compose/production/logto
docker compose down && docker compose up -d
```

### Recreate Bucket Configuration
If bucket is missing:
```bash
docker exec lobe-minio mc config host add minio http://localhost:9000 lobe_minio_user lobe_minio_password_123
docker exec lobe-minio mc mb minio/lobe
docker exec lobe-minio mc anonymous set public minio/lobe
```
