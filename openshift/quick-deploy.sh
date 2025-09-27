#!/bin/bash

# Quick OpenShift Deployment for Animal Facts Chat App
# Deploys directly from https://github.com/cloud-design-dev/chroma-roks-chat.git

set -e

NAMESPACE="kasten-demo-chatapp"
GITHUB_REPO="https://github.com/cloud-design-dev/chroma-roks-chat.git"
BRANCH=${1:-"main"}

echo "🚀 Deploying Animal Facts Chat App to OpenShift"
echo "📦 GitHub repo: $GITHUB_REPO"
echo "🌿 Branch: $BRANCH"

# Check prerequisites
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI (oc) not found. Please install it first."
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

# Update branch if different from main
if [ "$BRANCH" != "main" ]; then
    echo "📝 Using branch: $BRANCH"
    sed -i.bak "s|ref: main|ref: ${BRANCH}|g" openshift/build-configs.yaml
fi

# Backup current data if containers are running locally
echo "💾 Checking for current data to backup..."
if docker-compose ps 2>/dev/null | grep -q "chatapp-backend-1"; then
    echo "📋 Backing up current facts..."
    docker cp chatapp-backend-1:/app/data/animal_facts.json ./current-facts-backup.json 2>/dev/null || echo "⚠️  No existing facts found"
else
    echo "ℹ️  No running containers found, using default facts"
fi

# Deploy everything
echo "🏗️  Creating namespace and build configurations..."
oc apply -f openshift/build-configs.yaml

echo "🔨 Starting image builds from GitHub source..."
oc start-build chatapp-backend-build -n $NAMESPACE --follow &
BACKEND_PID=$!
oc start-build chatapp-frontend-build -n $NAMESPACE --follow &
FRONTEND_PID=$!

# Wait for both builds to complete
wait $BACKEND_PID
wait $FRONTEND_PID

echo "🚀 Deploying application manifests..."
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml

echo "⏳ Waiting for deployments to be ready..."
oc wait --for=condition=available deployment/chatapp-backend -n $NAMESPACE --timeout=300s
oc wait --for=condition=available deployment/chatapp-frontend -n $NAMESPACE --timeout=300s

# Configure CORS
echo "🔧 Configuring CORS..."
ROUTE_URL=$(oc get route chatapp-route -n $NAMESPACE -o jsonpath='{.spec.host}')
oc patch configmap chatapp-config -n $NAMESPACE \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

oc rollout restart deployment/chatapp-backend -n $NAMESPACE
oc rollout status deployment/chatapp-backend -n $NAMESPACE

# Restore custom facts if backup exists
if [ -f "./current-facts-backup.json" ]; then
    echo "📊 Restoring custom facts..."
    oc create configmap chatapp-initial-facts \
      --from-file=animal_facts.json=./current-facts-backup.json \
      -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -
    echo "✅ Custom facts backup created as ConfigMap"
fi

# Deploy Kasten policy
echo "📋 Deploying Kasten backup policy..."
oc apply -f openshift/kasten-policy.yaml 2>/dev/null || echo "⚠️  Kasten policy not applied (K10 may not be installed)"

# Cleanup
rm -f openshift/*.bak

echo ""
echo "🎉 Deployment complete!"
echo "🌐 Application URL: https://$ROUTE_URL"
echo ""
echo "🧪 Quick Test:"
echo "curl -s https://$ROUTE_URL/api/stats"
echo ""
echo "🔄 To rebuild from GitHub:"
echo "oc start-build chatapp-backend-build -n $NAMESPACE --follow"
echo "oc start-build chatapp-frontend-build -n $NAMESPACE --follow"