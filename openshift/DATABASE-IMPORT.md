# Database Import Guide for OpenShift

## 📋 Prerequisites

1. **Backup File**: Your local facts backup (JSON format)
2. **App Deployed**: Animal Facts Chat running in OpenShift  
3. **CLI Access**: `oc` logged into your OpenShift cluster

## 💾 Step 1: Create Your Backup (if not done already)

### From Running Local Docker:
```bash
# Export facts from local Docker container
docker cp chatapp-backend-1:/app/data/animal_facts.json ./my-custom-facts.json
```

### From OpenShift (existing deployment):
```bash
# Get facts from running OpenShift deployment
POD_NAME=$(oc get pod -l component=backend -n kasten-demo-chatapp -o jsonpath='{.items[0].metadata.name}')
oc cp $POD_NAME:/app/data/animal_facts.json ./openshift-facts.json -n kasten-demo-chatapp
```

## 🚀 Method 1: Import via API (Recommended)

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

## 🔧 Method 2: Direct Volume Import (Advanced)

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

## 📊 Method 3: Manual API Import

If you want more control, you can import facts manually:

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

## 🔍 Verify Import Success

### Check via Web UI:
1. Visit your OpenShift route URL
2. Look at the stats panel - should show your imported animals
3. Try querying for facts from your backup

### Check via API:
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

## 🛠️ Troubleshooting Import Issues

### Backend Not Ready:
```bash
# Check pod status
oc get pods -n kasten-demo-chatapp

# Check backend logs
oc logs -l component=backend -n kasten-demo-chatapp -f
```

### Route Not Found:
```bash
# Check if route exists
oc get route -n kasten-demo-chatapp

# Create route if missing
oc expose service chatapp-frontend-service -n kasten-demo-chatapp
```

### Import Failures:
```bash
# Check backend health
curl -s "https://$(oc get route chatapp-route -n kasten-demo-chatapp -o jsonpath='{.spec.host}')/api/stats"

# Validate JSON backup
jq empty my-custom-facts.json && echo "Valid JSON" || echo "Invalid JSON"
```

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

## 🎯 Best Practices

1. **Test Import First**: Try with a small subset of facts
2. **Backup Existing**: Export current state before importing
3. **Use API Method**: More reliable than direct file manipulation
4. **Verify Results**: Always check stats after import
5. **Monitor Logs**: Watch backend logs during import

## ⚡ Quick Import Commands

```bash
# Complete import workflow
./openshift/quick-deploy.sh                    # Deploy app
./openshift/import-database.sh backup.json    # Import your data
```

Your custom facts will now be available in your OpenShift deployment, ready for Kasten backup/restore demonstrations!