#!/bin/bash

# Alternative method: Direct volume import
# Usage: ./import-via-volume.sh <backup-file.json> [namespace]

set -e

BACKUP_FILE=${1:-"current-facts-backup.json"}
NAMESPACE=${2:-"kasten-demo-chatapp"}

echo "🔄 Importing database via persistent volume"
echo "📁 Backup file: $BACKUP_FILE"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file $BACKUP_FILE not found!"
    exit 1
fi

# Create ConfigMap from backup file
echo "📋 Creating ConfigMap from backup..."
oc create configmap chatapp-imported-facts \
  --from-file=animal_facts.json="$BACKUP_FILE" \
  -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -

# Get the backend pod
POD_NAME=$(oc get pod -l component=backend -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ Backend pod not found"
    exit 1
fi

echo "📦 Found backend pod: $POD_NAME"

# Copy facts to the pod's persistent data directory
echo "📥 Copying facts to persistent storage..."
oc exec $POD_NAME -n $NAMESPACE -- mkdir -p /app/persistent_data
oc cp "$BACKUP_FILE" "$POD_NAME:/app/persistent_data/animal_facts.json" -n $NAMESPACE

# Restart the deployment to load new facts
echo "🔄 Restarting backend to load imported facts..."
oc rollout restart deployment/chatapp-backend -n $NAMESPACE
oc rollout status deployment/chatapp-backend -n $NAMESPACE

echo "✅ Import complete via persistent volume"