#!/bin/bash

# OpenShift GitHub Source Build and Deploy Script
# Usage: ./deploy-from-github.sh <github-repo-url> [branch]

set -e

GITHUB_REPO=${1:-"https://github.com/your-username/kasten-roks-demo-apps.git"}
BRANCH=${2:-"main"}
NAMESPACE="kasten-demo-chatapp"

echo "🚀 Deploying Animal Facts Chat App from GitHub source to OpenShift"
echo "📦 GitHub repo: $GITHUB_REPO"
echo "🌿 Branch: $BRANCH"

# Check if oc is available and user is logged in
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI (oc) not found. Please install it first."
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

# Step 1: Configure branch if different from main
echo "📝 Using GitHub repo: ${GITHUB_REPO}..."
echo "📝 Using branch: ${BRANCH}..."

# Update branch if different from main
if [ "$BRANCH" != "main" ]; then
    sed -i.bak "s|ref: main|ref: ${BRANCH}|g" openshift/build-configs.yaml
fi

# Step 2: Backup current data if containers are running locally
echo "💾 Checking for current data to backup..."
if docker-compose ps 2>/dev/null | grep -q "chatapp-backend-1"; then
    echo "📋 Backing up current facts..."
    docker cp chatapp-backend-1:/app/data/animal_facts.json ./current-facts-backup.json 2>/dev/null || echo "⚠️  No existing facts found"
else
    echo "ℹ️  No running containers found, using default facts"
fi

# Step 3: Create namespace and apply build configs
echo "🏗️  Creating namespace and build configurations..."
oc apply -f openshift/build-configs.yaml

# Step 4: Start builds
echo "🔨 Starting image builds from GitHub source..."
oc start-build chatapp-backend-build -n $NAMESPACE --follow
oc start-build chatapp-frontend-build -n $NAMESPACE --follow

# Step 5: Deploy application manifests
echo "🚀 Deploying application manifests..."
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml

# Step 6: Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
oc wait --for=condition=available deployment/chatapp-backend -n $NAMESPACE --timeout=300s
oc wait --for=condition=available deployment/chatapp-frontend -n $NAMESPACE --timeout=300s

# Step 7: Configure CORS
echo "🔧 Configuring CORS..."
ROUTE_URL=$(oc get route chatapp-route -n $NAMESPACE -o jsonpath='{.spec.host}')
oc patch configmap chatapp-config -n $NAMESPACE \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

# Restart backend to pick up new config
oc rollout restart deployment/chatapp-backend -n $NAMESPACE

# Step 8: Restore custom facts if backup exists
if [ -f "./current-facts-backup.json" ]; then
    echo "📊 Restoring custom facts..."
    
    # Wait for backend to be ready after restart
    oc rollout status deployment/chatapp-backend -n $NAMESPACE
    
    # Create ConfigMap with custom facts
    oc create configmap chatapp-initial-facts \
      --from-file=animal_facts.json=./current-facts-backup.json \
      -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -
    
    echo "✅ Custom facts backup created as ConfigMap"
    echo "💡 You can now restore these facts via the API or by mounting the ConfigMap"
fi

# Step 9: Deploy Kasten policy (optional)
read -p "🛡️  Deploy Kasten backup policy? (y/N): " deploy_kasten
if [[ $deploy_kasten =~ ^[Yy]$ ]]; then
    echo "📋 Deploying Kasten backup policy..."
    oc apply -f openshift/kasten-policy.yaml || echo "⚠️  Kasten may not be installed or policy needs adjustment"
fi

# Cleanup
rm -f openshift/*.bak

echo ""
echo "🎉 Deployment complete!"
echo "🌐 Application URL: https://$ROUTE_URL"
echo ""
echo "📋 Next steps:"
echo "1. Visit the application URL to test functionality"
echo "2. Add some custom facts using the UI"
echo "3. Configure Kasten backup in the K10 dashboard"
echo "4. Set up GitHub webhooks for automatic rebuilds"
echo ""
echo "🔄 GitHub Webhook URLs (for automatic builds):"
BACKEND_WEBHOOK=$(oc describe bc/chatapp-backend-build -n $NAMESPACE | grep "Webhook GitHub" -A1 | tail -1 | awk '{print $1}')
FRONTEND_WEBHOOK=$(oc describe bc/chatapp-frontend-build -n $NAMESPACE | grep "Webhook GitHub" -A1 | tail -1 | awk '{print $1}')
echo "   Backend:  $BACKEND_WEBHOOK"
echo "   Frontend: $FRONTEND_WEBHOOK"
echo ""
echo "🔍 Useful commands:"
echo "  oc get pods -n $NAMESPACE"
echo "  oc logs -l component=backend -n $NAMESPACE -f"
echo "  oc start-build chatapp-backend-build -n $NAMESPACE --follow"
echo "  curl -s https://$ROUTE_URL/api/stats"