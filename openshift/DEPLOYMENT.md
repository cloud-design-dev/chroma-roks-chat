# Animal Facts Chat App - OpenShift Deployment Guide

## 📋 Prerequisites

1. **OpenShift Cluster Access**: CLI (`oc`) configured and logged in
2. **Container Registry**: Push access to a container registry accessible by OpenShift
3. **Kasten K10**: Installed and configured in your OpenShift cluster
4. **Storage Class**: Available persistent storage (update `storageClassName` in manifests)

## 🚀 Step 1: Build and Push Container Images

### Build Images
```bash
# Build both images with proper tags for your registry
docker build -t your-registry.com/chatapp-backend:latest ./backend
docker build -t your-registry.com/chatapp-frontend:latest ./frontend

# Push to your container registry
docker push your-registry.com/chatapp-backend:latest
docker push your-registry.com/chatapp-frontend:latest
```

### Update Image References
Edit the OpenShift manifests to use your container registry:
```bash
# Update backend.yaml and frontend.yaml
sed -i 's|chatapp-backend:latest|your-registry.com/chatapp-backend:latest|g' openshift/backend.yaml
sed -i 's|chatapp-frontend:latest|your-registry.com/chatapp-frontend:latest|g' openshift/frontend.yaml
```

## 💾 Step 2: Backup Current Database Facts

### Extract Current Facts Data
```bash
# Copy your current facts from running container
docker-compose ps
docker cp chatapp-backend-1:/app/data/animal_facts.json ./current-facts-backup.json

# Alternatively, if you added facts via the UI, create a backup via API
curl -s http://localhost:8000/api/stats > current-stats-backup.json
```

### Create ConfigMap with Your Current Facts
```bash
# Create a ConfigMap with your current animal facts
oc create configmap chatapp-initial-facts \
  --from-file=animal_facts.json=./current-facts-backup.json \
  -n kasten-demo-chatapp
```

## 🏗️ Step 3: Deploy to OpenShift

### Apply Manifests
```bash
# Create namespace and deploy application
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml

# Wait for deployments to be ready
oc wait --for=condition=available deployment/chatapp-backend -n kasten-demo-chatapp --timeout=300s
oc wait --for=condition=available deployment/chatapp-frontend -n kasten-demo-chatapp --timeout=300s
```

### Update CORS Configuration
```bash
# Get the route URL
ROUTE_URL=$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')
echo "Application will be available at: https://$ROUTE_URL"

# Update ConfigMap with correct CORS origin
oc patch configmap chatapp-config -n kasten-demo-chatapp \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

# Restart backend to pick up new config
oc rollout restart deployment/chatapp-backend -n kasten-demo-chatapp
```

## 📊 Step 4: Restore Your Custom Facts

### Method 1: Via API (Recommended)
```bash
# Get the application URL
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"

# Add your custom facts via API calls
# Example: Add a custom fact you created locally
curl -X POST "$APP_URL/api/add_fact" \
  -H "Content-Type: application/json" \
  -d '{"animal":"giraffe","fact":"Giraffes have the same number of neck vertebrae as humans - just 7!"}'

# Verify facts are added
curl -s "$APP_URL/api/stats" | jq
```

### Method 2: Via Persistent Volume (Advanced)
```bash
# Copy facts file directly to persistent volume
POD_NAME=$(oc get pod -l component=backend -n kasten-demo-chatapp -o jsonpath='{.items[0].metadata.name}')

# Copy your backup to the pod
oc cp ./current-facts-backup.json $POD_NAME:/app/persistent_data/animal_facts.json -n kasten-demo-chatapp

# Restart the backend to load the new facts
oc rollout restart deployment/chatapp-backend -n kasten-demo-chatapp
```

## 🛡️ Step 5: Configure Kasten Backup

### Apply Kasten Policy
```bash
# Update the policy with your actual profile name
sed -i 's|default-profile|your-kasten-profile-name|g' openshift/kasten-policy.yaml

# Apply Kasten backup policy
oc apply -f openshift/kasten-policy.yaml
```

### Verify Kasten Configuration
1. **Access Kasten Dashboard**: Usually at `https://k10-kasten-io.apps.your-cluster.com`
2. **Check Applications**: Verify "kasten-demo-chatapp" appears in Applications
3. **View Policies**: Confirm "chatapp-backup-policy" is active
4. **Run Manual Backup**: Create an initial backup for demo

## 🎯 Step 6: Demo Flow Verification

### Test the Application
```bash
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"
echo "Access your app at: $APP_URL"

# Test backend API
curl -s "$APP_URL/api/stats"
curl -X POST "$APP_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"query":"Tell me about lions"}'
```

### Demo Scenario
1. **Show Initial State**: Display animal facts in UI
2. **Add New Facts**: Use the "Add New Fact" button to add both correct and incorrect facts
3. **Create Backup**: Manually trigger backup in Kasten UI
4. **Simulate Disaster**: Delete the backend deployment
5. **Restore**: Use Kasten to restore the application
6. **Verify Restoration**: Check that data is restored correctly

## 🔧 Troubleshooting

### Check Pod Logs
```bash
# Backend logs
oc logs -l component=backend -n kasten-demo-chatapp -f

# Frontend logs  
oc logs -l component=frontend -n kasten-demo-chatapp -f
```

### Debug Networking
```bash
# Test internal connectivity
oc exec -it deployment/chatapp-frontend -n kasten-demo-chatapp -- curl http://chatapp-backend-service:8000/api/stats
```

### Storage Issues
```bash
# Check PVC status
oc get pvc -n kasten-demo-chatapp
oc describe pvc chatapp-data -n kasten-demo-chatapp
```

## 📝 Notes for Demo

- **Persistent Data**: The PVC ensures data survives pod restarts
- **Kasten Integration**: Policy backs up both configuration and persistent data
- **OpenShift Security**: All containers run as non-root with proper security contexts
- **Scalability**: Ready for horizontal scaling if needed
- **Monitoring**: Health checks ensure reliability

Your Animal Facts Chat App is now ready for Kasten backup/restore demonstrations in OpenShift!