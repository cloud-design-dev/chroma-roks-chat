# GitHub Source Build Deployment Guide

## 🌐 Building from GitHub Source

OpenShift can build your container images directly from GitHub source code. This approach uses BuildConfig objects to build images, then deploys them using your manifest files.

### How it Works:
1. **BuildConfig** objects pull source code from GitHub
2. **OpenShift builds** container images using your Dockerfiles  
3. **ImageStreams** store the built images internally
4. **Deployment manifests** reference the ImageStream images
5. **All other manifests** (ConfigMaps, Services, Routes, Kasten policies) are applied separately

## 🚀 Quick Start with GitHub Source

### Prerequisites:
- GitHub repository with your code
- OpenShift cluster access
- Code pushed to GitHub

### Deploy from GitHub:
```bash
# Deploy everything from your GitHub repo (no parameters needed)
./openshift/deploy-from-github.sh

# Or specify different branch
./openshift/deploy-from-github.sh https://github.com/cloud-design-dev/chroma-roks-chat.git feature-branch
```

## 📋 Step-by-Step GitHub Source Deployment

### 1. Repository is Ready
```bash
# Your code is already at:
# https://github.com/cloud-design-dev/chroma-roks-chat.git
# No changes needed to build-configs.yaml
```

### 2. Apply Build Resources
```bash
# Create ImageStreams and BuildConfigs
oc apply -f openshift/build-configs.yaml
```

### 3. Start Image Builds
```bash
# Build backend image from GitHub source
oc start-build chatapp-backend-build -n kasten-demo-chatapp --follow

# Build frontend image from GitHub source  
oc start-build chatapp-frontend-build -n kasten-demo-chatapp --follow
```

### 4. Deploy Application Manifests
```bash
# Deploy all other resources (these reference the built images)
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml
oc apply -f openshift/kasten-policy.yaml
```

### 5. Configure and Test
```bash
# Get route URL and configure CORS
ROUTE_URL=$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')
oc patch configmap chatapp-config -n kasten-demo-chatapp \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

# Restart backend to pick up config
oc rollout restart deployment/chatapp-backend -n kasten-demo-chatapp
```

## 🔄 Automated Rebuilds with Webhooks

### Set up GitHub Webhooks:
```bash
# Get webhook URLs
oc describe bc/chatapp-backend-build -n kasten-demo-chatapp | grep "Webhook GitHub"
oc describe bc/chatapp-frontend-build -n kasten-demo-chatapp | grep "Webhook GitHub"
```

### Configure in GitHub:
1. Go to your GitHub repo → Settings → Webhooks
2. Add webhook URL from OpenShift
3. Set Content-Type: `application/json`
4. Secret: `my_super_secret_token` (or update in build-configs.yaml)
5. Events: Push events

Now pushes to your repo will automatically trigger rebuilds!

## 📊 Data Migration from Local Docker

### Backup Current Facts:
```bash
# If you have local containers running with custom facts
docker cp chatapp-backend-1:/app/data/animal_facts.json ./current-facts-backup.json
```

### Restore to OpenShift:
```bash
# Method 1: Via ConfigMap (recommended)
oc create configmap chatapp-initial-facts \
  --from-file=animal_facts.json=./current-facts-backup.json \
  -n kasten-demo-chatapp

# Method 2: Via API calls to the running app
APP_URL="https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')"
curl -X POST "$APP_URL/api/add_fact" \
  -H "Content-Type: application/json" \
  -d '{"animal":"your-animal","fact":"your-custom-fact"}'
```

## 🛠️ Key Differences from Registry Build

| Aspect | GitHub Source Build | Registry Build |
|--------|-------------------|---------------|
| **Image Building** | OpenShift builds from source | You build and push images |
| **Automation** | GitHub webhooks trigger rebuilds | Manual or CI/CD pipeline |
| **Source Control** | Always matches your GitHub repo | May drift from source |
| **Build Logs** | Available in OpenShift console | Local build logs |
| **Security** | OpenShift handles base image updates | You manage base images |

## 🔧 Troubleshooting GitHub Builds

### Check Build Status:
```bash
# List all builds
oc get builds -n kasten-demo-chatapp

# Watch a build in progress
oc logs -f build/chatapp-backend-build-1 -n kasten-demo-chatapp

# Start a new build manually
oc start-build chatapp-backend-build -n kasten-demo-chatapp
```

### Debug Build Issues:
```bash
# Check BuildConfig
oc describe bc/chatapp-backend-build -n kasten-demo-chatapp

# Check ImageStream
oc describe is/chatapp-backend -n kasten-demo-chatapp

# Verify webhook secrets
oc get secret github-webhook-secret -n kasten-demo-chatapp -o yaml
```

## ✅ Benefits of GitHub Source Builds

- **🔄 Automatic Updates**: Webhooks rebuild on git push
- **🔒 Security**: OpenShift manages base image updates  
- **📊 Auditability**: All builds tracked in OpenShift
- **🏗️ Consistency**: Same build environment every time
- **🚀 GitOps Ready**: Perfect for GitOps workflows

Your Animal Facts Chat App will be built directly from your GitHub source and deployed with all your manifest files!