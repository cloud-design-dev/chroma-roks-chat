#!/bin/bash

# OpenShift Deployment Script for Animal Facts Chat App
# Usage: ./deploy-to-openshift.sh <your-container-registry>

set -e

REGISTRY=${1:-"your-registry.com"}
NAMESPACE="kasten-demo-chatapp"

echo "🚀 Deploying Animal Facts Chat App to OpenShift"
echo "📦 Using registry: $REGISTRY"

# Check if oc is available and user is logged in
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI (oc) not found. Please install it first."
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

# Step 1: Build and push images
echo "🔨 Building container images..."
docker build -t ${REGISTRY}/chatapp-backend:latest ./backend
docker build -t ${REGISTRY}/chatapp-frontend:latest ./frontend

echo "📤 Pushing images to registry..."
docker push ${REGISTRY}/chatapp-backend:latest
docker push ${REGISTRY}/chatapp-frontend:latest

# Step 2: Update manifests with registry
echo "📝 Updating manifests with registry..."
sed -i.bak "s|chatapp-backend:latest|${REGISTRY}/chatapp-backend:latest|g" openshift/backend.yaml
sed -i.bak "s|chatapp-frontend:latest|${REGISTRY}/chatapp-frontend:latest|g" openshift/frontend.yaml

# Step 3: Backup current data if containers are running
echo "💾 Checking for current data to backup..."
if docker-compose ps | grep -q "chatapp-backend-1"; then
    echo "📋 Backing up current facts..."
    docker cp chatapp-backend-1:/app/data/animal_facts.json ./current-facts-backup.json 2>/dev/null || echo "⚠️  No existing facts found"
else
    echo "ℹ️  No running containers found, using default facts"
fi

# Step 4: Deploy to OpenShift
echo "🏗️  Deploying to OpenShift..."
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml

# Step 5: Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
oc wait --for=condition=available deployment/chatapp-backend -n $NAMESPACE --timeout=300s
oc wait --for=condition=available deployment/chatapp-frontend -n $NAMESPACE --timeout=300s

# Step 6: Configure CORS
echo "🔧 Configuring CORS..."
ROUTE_URL=$(oc get route chatapp-route -n $NAMESPACE -o jsonpath='{.spec.host}')
oc patch configmap chatapp-config -n $NAMESPACE \
  --patch='{"data":{"CORS_ORIGINS":"https://'$ROUTE_URL'"}}'

# Restart backend to pick up new config
oc rollout restart deployment/chatapp-backend -n $NAMESPACE

# Step 7: Restore custom facts if backup exists
if [ -f "./current-facts-backup.json" ]; then
    echo "📊 Restoring custom facts..."
    
    # Wait for backend to be ready after restart
    oc rollout status deployment/chatapp-backend -n $NAMESPACE
    
    # Create ConfigMap with custom facts
    oc create configmap chatapp-initial-facts \
      --from-file=animal_facts.json=./current-facts-backup.json \
      -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -
    
    echo "✅ Custom facts backup created as ConfigMap"
fi

# Step 8: Deploy Kasten policy (optional)
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
echo "4. Run your demo!"
echo ""
echo "🔍 Useful commands:"
echo "  oc get pods -n $NAMESPACE"
echo "  oc logs -l component=backend -n $NAMESPACE -f"
echo "  curl -s https://$ROUTE_URL/api/stats"