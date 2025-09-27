# Animal Facts Chat App - OpenShift Deployment Guide

## 🌟 Ready-to-Deploy Configuration

All manifest files have been updated to use your GitHub repository: 
**https://github.com/cloud-design-dev/chroma-roks-chat.git**

## 📋 Prerequisites

1. **OpenShift Cluster Access**: CLI (`oc`) configured and logged in
2. **Kasten K10**: Installed and configured in your OpenShift cluster (optional for basic deployment)
3. **GitHub Repository**: Code pushed to https://github.com/cloud-design-dev/chroma-roks-chat.git
4. **Storage Class**: Available persistent storage (default `gp2` configured in manifests)

## 🚀 Quick Deployment (Recommended)

### Instant Deploy from GitHub Source:
```bash
# Deploy from GitHub source (no configuration needed)
./openshift/quick-deploy.sh

# Or specify a different branch
./openshift/quick-deploy.sh feature-branch
```

This script will:
1. ✅ Build backend and frontend images from your GitHub repo
2. ✅ Deploy all manifests (namespace, configs, services, routes)
3. ✅ Configure CORS automatically
4. ✅ Set up Kasten backup policy
5. ✅ Preserve any local facts you've added

## 📋 Manual Step-by-Step Deployment

### 1. Apply Build Configurations
```bash
# Create ImageStreams and BuildConfigs (points to your GitHub repo)
oc apply -f openshift/build-configs.yaml
```

### 2. Build Images from GitHub Source
```bash
# Build both images from your GitHub repository
oc start-build chatapp-backend-build -n kasten-demo-chatapp --follow
oc start-build chatapp-frontend-build -n kasten-demo-chatapp --follow
```

### 3. Deploy Application Components
```bash
# Deploy backend, frontend, and services
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml

# Wait for deployments to be ready
oc wait --for=condition=available deployment/chatapp-backend -n kasten-demo-chatapp --timeout=300s
oc wait --for=condition=available deployment/chatapp-frontend -n kasten-demo-chatapp --timeout=300s
```

### 4. Configure CORS and Access
```bash
# Get the route URL
ROUTE_URL=$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')
echo "Application available at: https://$ROUTE_URL"

# Update CORS configuration
oc patch configmap chatapp-config -n kasten-demo-chatapp \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

# Restart backend to apply CORS config
oc rollout restart deployment/chatapp-backend -n kasten-demo-chatapp
```

### 5. Apply Kasten Backup Policy
```bash
# Deploy Kasten K10 backup policy
oc apply -f openshift/kasten-policy.yaml
```

## 💾 Database Import from Local Docker

### Step 1: Create Your Backup

#### Current Deployment Facts:
```bash
# Export current facts (includes base facts + any custom ones added via UI)
./openshift/export-database.sh kasten-demo-chatapp

# This creates a backup file with timestamp: openshift-facts-backup-YYYYMMDD-HHMMSS.json
```

#### From Local Docker (if available):
```bash
# Export facts from local Docker container (if running)
docker cp chatapp-backend-1:/app/data/animal_facts.json ./my-custom-facts.json 2>/dev/null || echo "Local container not found"
```

**Important Note**: The current implementation uses in-memory vector storage. The backup script creates a snapshot of the base facts. Any custom facts added via the UI will need to be re-added after import, or you can use the Kasten backup/restore process to preserve the complete application state.

### Step 2: Import Methods

#### Method 1: Import via API (Recommended)
This method adds facts through the application API, preserving any existing data.

```bash
# Import your backup file
./openshift/import-database.sh my-custom-facts.json

# Or specify different namespace
./openshift/import-database.sh my-custom-facts.json my-namespace
```

**What it does:**
- ✅ Validates backup file format
- ✅ Checks app is running and accessible  
- ✅ Adds facts one-by-one via API
- ✅ Shows import progress and final stats
- ✅ Preserves existing facts (no overwrite)

#### Method 2: Direct Volume Import (Advanced)
This method directly copies the backup to persistent storage and restarts the app.

```bash
# Import via persistent volume
./openshift/import-via-volume.sh my-custom-facts.json

# Or specify different namespace  
./openshift/import-via-volume.sh my-custom-facts.json my-namespace
```

**What it does:**
- ✅ Creates ConfigMap from backup
- ✅ Copies directly to persistent storage
- ✅ Restarts backend to reload data
- ⚠️ May overwrite existing facts

#### Method 3: Manual API Import
For fine-grained control over individual facts:

```bash
# Get your app URL
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"

# Add individual facts
curl -X POST "$APP_URL/api/add_fact" \
  -H "Content-Type: application/json" \
  -d '{"animal":"giraffe","fact":"Giraffes have the same number of neck vertebrae as humans!"}'

# Check current stats
curl -s "$APP_URL/api/stats" | jq
```

### Step 3: Verify Import Success

#### Check via Web UI:
1. Visit your OpenShift route URL
2. Look at the stats panel - should show your imported animals
3. Try querying for facts from your backup

#### Check via API:
```bash
# Get app URL
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"

# View current stats
curl -s "$APP_URL/api/stats"

# Test a query
curl -X POST "$APP_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"query":"Tell me about giraffes"}' | jq '.response'
```

## 🔄 GitHub Webhooks for Auto-Rebuild

### Get Webhook URLs:
```bash
# Get the webhook URLs for GitHub
oc describe bc/chatapp-backend-build -n kasten-demo-chatapp | grep "Webhook GitHub"
oc describe bc/chatapp-frontend-build -n kasten-demo-chatapp | grep "Webhook GitHub"
```

### Configure in GitHub:
1. Go to https://github.com/cloud-design-dev/chroma-roks-chat/settings/hooks
2. Add webhook URL from OpenShift
3. Set Content-Type: `application/json`
4. Secret: `my_super_secret_token`
5. Events: Push events

Now any push to your repository will automatically trigger image rebuilds!

## 🔧 Monitoring and Troubleshooting

### Check Application Status:
```bash
# View all resources
oc get all -n kasten-demo-chatapp

# Check pod logs
oc logs -l component=backend -n kasten-demo-chatapp -f
oc logs -l component=frontend -n kasten-demo-chatapp -f

# Check build logs
oc logs -f build/chatapp-backend-build-1 -n kasten-demo-chatapp
```

### Test the Application:
```bash
# Get the route URL
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"

# Test backend API
curl -s "$APP_URL/api/stats"
curl -X POST "$APP_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"query":"Tell me about 🦁 lions"}'
```

### Rebuild Images:
```bash
# Trigger new builds manually
oc start-build chatapp-backend-build -n kasten-demo-chatapp
oc start-build chatapp-frontend-build -n kasten-demo-chatapp
```

### Database Import Issues:

#### Backend Not Ready:
```bash
# Check pod status
oc get pods -n kasten-demo-chatapp

# Check backend logs
oc logs -l component=backend -n kasten-demo-chatapp -f
```

#### Route Not Found:
```bash
# Check if route exists
oc get route -n kasten-demo-chatapp

# Create route if missing
oc expose service chatapp-frontend-service -n kasten-demo-chatapp
```

#### Import Failures:
```bash
# Check backend health
curl -s "https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')/api/stats"

# Validate JSON backup
jq empty my-custom-facts.json && echo "Valid JSON" || echo "Invalid JSON"
```

### Debug Networking:
```bash
# Test internal connectivity
oc exec -it deployment/chatapp-frontend -n kasten-demo-chatapp -- curl http://chatapp-backend-service:8000/api/stats
```

### Storage Issues:
```bash
# Check PVC status
oc get pvc -n kasten-demo-chatapp
oc describe pvc chatapp-data -n kasten-demo-chatapp
```

## 🎯 Kasten Demo Flow

With your app deployed in OpenShift:

1. **Show Initial State** → Visit the app, show animal facts stats with 🦁🐘🐬 emojis
2. **Add Custom Facts** → Use the ➕ Add New Fact button to add data
3. **Create Backup** → Use Kasten K10 dashboard to backup the namespace
4. **Add Incorrect Facts** → Add obviously wrong information for demo
5. **Simulate Disaster** → Delete the backend deployment or corrupt data
6. **Restore with Kasten** → Use K10 to restore to the backup point
7. **Verify Restoration** → Show that incorrect facts are gone, data restored

### Kasten Configuration:
1. **Access Kasten Dashboard**: Usually at `https://k10-kasten-io.apps.your-cluster.com`
2. **Check Applications**: Verify "kasten-demo-chatapp" appears in Applications
3. **View Policies**: Confirm "chatapp-backup-policy" is active
4. **Run Manual Backup**: Create an initial backup for demo

## 📈 Expected Backup File Format

Your backup should be JSON array format:
```json
[
  {
    "animal": "lion",
    "fact": "Lions are social cats that live in groups called prides."
  },
  {
    "animal": "elephant", 
    "fact": "Elephants have excellent memories and can remember other elephants for decades."
  }
]
```

## 🎯 Best Practices for OpenShift

1. **Never Hardcode UIDs**: Let OpenShift assign arbitrary UIDs in the allowed range
2. **Always Set seccompProfile**: Required for restricted security contexts  
3. **Use In-Memory Storage**: Current implementation uses scikit-learn vector storage
4. **Backup via Kasten**: For complete application state preservation
5. **Export Base Facts**: Use export script for baseline fact recovery
6. **Test Import First**: Try with a small subset of facts
7. **Monitor Logs**: Watch backend logs during import

## ⚡ Quick Commands Summary

```bash
# Complete deployment and import workflow
./openshift/quick-deploy.sh                    # Deploy app from GitHub
./openshift/export-database.sh                 # Export current facts  
./openshift/import-database.sh backup.json     # Import facts to deployment

# Manual deployment
oc apply -f openshift/build-configs.yaml       # Create builds
oc start-build chatapp-backend-build --follow  # Build backend
oc start-build chatapp-frontend-build --follow # Build frontend
oc apply -f openshift/backend.yaml             # Deploy backend
oc apply -f openshift/frontend.yaml            # Deploy frontend

# Get application URL
oc get route chatapp-route -n kasten-demo-chatapp
```

## ✨ What's Included

- **🏗️ BuildConfigs**: Build images from your GitHub repository
- **⚡ UV Backend**: Ultra-fast Python package installation with virtual environment
- **🎨 Emoji UI**: Beautiful interface with animal emojis and IBM Carbon Design System
- **🔐 Security**: OpenShift-compatible security contexts and SCCs  
- **📦 Persistence**: PVC for data that survives pod restarts
- **🌐 Networking**: Route with TLS termination for HTTPS access
- **🛡️ Backup**: Kasten K10 policy for automated backups
- **📊 Monitoring**: Health checks and proper logging
- **🔄 CI/CD Ready**: Webhook support for auto-rebuilds
- **💾 Data Import**: Multiple methods for importing custom facts

Your Animal Facts Chat App is now ready for production OpenShift deployment with comprehensive Kasten backup/restore demonstrations! 🚀