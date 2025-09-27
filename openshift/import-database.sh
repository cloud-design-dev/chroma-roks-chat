#!/bin/bash

# Database Import Script for OpenShift Deployment  
# Usage: ./import-database.sh <backup-file.json> [namespace]
# Note: Current implementation uses in-memory vector storage

set -e

BACKUP_FILE=${1:-"openshift-facts-backup.json"}
NAMESPACE=${2:-"kasten-demo-chatapp"}

echo "🔄 Importing database backup to OpenShift deployment"
echo "📁 Backup file: $BACKUP_FILE"
echo "🏗️ Namespace: $NAMESPACE"
echo "💡 Note: App uses in-memory storage - facts imported via API"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file $BACKUP_FILE not found!"
    echo "💡 Create a backup first:"
    echo "   ./openshift/export-database.sh"
    echo "   or from local Docker:"
    echo "   docker cp chatapp-backend-1:/app/data/animal_facts.json ./backup.json 2>/dev/null"
    exit 1
fi

# Check if oc is available and user is logged in
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI (oc) not found"
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

# Get the application URL
APP_URL="https://$(oc get route chatapp-route -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)"
if [ -z "$APP_URL" ] || [ "$APP_URL" = "https://" ]; then
    echo "❌ Application route not found. Is the app deployed?"
    echo "💡 Deploy first: ./openshift/quick-deploy.sh"
    exit 1
fi

echo "🌐 Application URL: $APP_URL"

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -s "$APP_URL/api/stats" >/dev/null 2>&1; then
        echo "✅ Backend is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Backend not responding after 5 minutes"
        echo "🔍 Check pod status: oc get pods -n $NAMESPACE"
        exit 1
    fi
    sleep 10
done

# Show current state
echo "📊 Current database state:"
curl -s "$APP_URL/api/stats" | jq -r 'to_entries[] | "  \(.key): \(.value) facts"' || echo "  Unable to parse current stats"

# Import facts from backup
echo "📥 Importing facts from backup..."

# Check if backup file is valid JSON
if ! jq empty "$BACKUP_FILE" 2>/dev/null; then
    echo "❌ Invalid JSON in backup file"
    exit 1
fi

# Count facts to import
FACT_COUNT=$(jq length "$BACKUP_FILE")
echo "📋 Found $FACT_COUNT facts to import"

# Import facts one by one
IMPORTED=0
FAILED=0

jq -c '.[]' "$BACKUP_FILE" | while read -r fact; do
    ANIMAL=$(echo "$fact" | jq -r '.animal')
    FACT_TEXT=$(echo "$fact" | jq -r '.fact')
    
    echo "Adding fact for $ANIMAL..."
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$APP_URL/api/add_fact" \
        -H "Content-Type: application/json" \
        -d "{\"animal\":\"$ANIMAL\",\"fact\":\"$FACT_TEXT\"}")
    
    if [ "$RESPONSE" = "200" ]; then
        ((IMPORTED++))
        echo "  ✅ Added fact for $ANIMAL"
    else
        ((FAILED++))
        echo "  ❌ Failed to add fact for $ANIMAL (HTTP $RESPONSE)"
    fi
    
    # Small delay to avoid overwhelming the API
    sleep 0.5
done

# Show final state
echo ""
echo "📊 Import completed!"
echo "  ✅ Imported: $IMPORTED facts"
echo "  ❌ Failed: $FAILED facts"
echo ""
echo "📈 Final database state:"
curl -s "$APP_URL/api/stats" | jq -r 'to_entries[] | "  \(.key): \(.value) facts"' || echo "  Unable to parse final stats"

echo ""
echo "🎉 Database import complete!"
echo "🌐 Visit your app: $APP_URL"