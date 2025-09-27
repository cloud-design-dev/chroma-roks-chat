# Animal Facts Chat App - OpenShift Deployment

## 🌟 Ready-to-Deploy Configuration

All manifest files have been updated to use your GitHub repository: 
**https://github.com/cloud-design-dev/chroma-roks-chat.git**

## 🚀 Quick Deployment (Recommended)

### Instant Deploy:
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

## 💾 Data Migration from Local Docker

### Backup Your Local Facts:
```bash
# If you have custom facts in local containers
docker cp chatapp-backend-1:/app/data/animal_facts.json ./local-facts-backup.json
```

### Restore to OpenShift:
```bash
# Get the app URL
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"

# Add your custom facts via API
curl -X POST "$APP_URL/api/add_fact" \
  -H "Content-Type: application/json" \
  -d '{"animal":"giraffe","fact":"Your custom giraffe fact here!"}'

# Verify the facts were added
curl -s "$APP_URL/api/stats" | jq
```

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

## 🎯 Kasten Demo Flow

With your app deployed in OpenShift:

1. **Show Initial State** → Visit the app, show animal facts stats
2. **Add Custom Facts** → Use the ➕ Add New Fact button to add data
3. **Create Backup** → Use Kasten K10 dashboard to backup the namespace
4. **Add Incorrect Facts** → Add obviously wrong information for demo
5. **Simulate Disaster** → Delete the backend deployment or corrupt data
6. **Restore with Kasten** → Use K10 to restore to the backup point
7. **Verify Restoration** → Show that incorrect facts are gone, data restored

## ✨ What's Included

- **🏗️ BuildConfigs**: Build images from your GitHub repository
- **🔐 Security**: OpenShift-compatible security contexts and SCCs  
- **📦 Persistence**: PVC for data that survives pod restarts
- **🌐 Networking**: Route with TLS termination for HTTPS access
- **🛡️ Backup**: Kasten K10 policy for automated backups
- **📊 Monitoring**: Health checks and proper logging
- **🔄 CI/CD Ready**: Webhook support for auto-rebuilds

Your Animal Facts Chat App is now ready for production OpenShift deployment with Kasten backup/restore demonstrations!