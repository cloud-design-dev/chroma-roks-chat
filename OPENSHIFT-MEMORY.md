# 📚 Crush Memory: OpenShift Deployment Guidelines

## 🔒 OpenShift Security Context Requirements

**CRITICAL**: OpenShift clusters (especially ROKS/IBM) have strict Security Context Constraints that require:

### ✅ **Required Security Context Settings**
```yaml
# Pod Level Security Context
securityContext:
  runAsNonRoot: true              # Required
  seccompProfile:                 # REQUIRED for restricted policy
    type: RuntimeDefault
  # DO NOT SET runAsUser or fsGroup - let OpenShift assign arbitrary UIDs

# Container Level Security Context  
securityContext:
  allowPrivilegeEscalation: false # Required
  runAsNonRoot: true              # Required
  seccompProfile:                 # REQUIRED for restricted policy
    type: RuntimeDefault
  capabilities:
    drop: ["ALL"]                 # Required
  # DO NOT SET runAsUser - let OpenShift assign from allowed range
```

### ❌ **Common Mistakes to Avoid**
- ❌ Hardcoding `runAsUser: 1001` (will fail with "must be in ranges [1000650000, 1000659999]")
- ❌ Setting `fsGroup: 1001` (will fail with "not an allowed group")
- ❌ Missing `seccompProfile.type: RuntimeDefault` (will violate PodSecurity policy)
- ❌ Not dropping all capabilities
- ❌ Allowing privilege escalation

### 🔧 **Dockerfile Considerations**
- Build images with non-root user for compatibility
- Use `USER 1001` in Dockerfile for local development
- OpenShift will override with arbitrary UID in allowed range
- Ensure file permissions are group-writable (`chmod -R g+rwX`)

## 📊 **Database Backup/Import Process**

The current implementation uses **in-memory vector storage** (scikit-learn + TF-IDF), not file-based persistence:

### ✅ **Correct Backup Method**
```bash
# Export via API (creates timestamped backup)
./openshift/export-database.sh

# Import via API to new deployment
./openshift/import-database.sh backup-file.json
```

### ❌ **Incorrect Methods** 
- ❌ `oc cp` from `/app/data/animal_facts.json` (file doesn't exist in running container)
- ❌ Direct file system manipulation (facts are in memory only)
- ❌ Volume mounting for data extraction (no persistent data files)

## 🎯 **Kasten Demo Strategy**

For backup/restore demonstrations:
1. **Use Kasten for full namespace backup** (includes PVC and application state)
2. **Add custom facts via UI** after creating backup point
3. **Simulate disaster** by deleting deployment or corrupting state  
4. **Restore via Kasten** to demonstrate complete application recovery

## 💡 **Key Reminders for Crush**

- **Always use arbitrary UIDs** in OpenShift - never hardcode user/group IDs
- **Always include seccompProfile** for OpenShift restricted security contexts
- **Database is in-memory** - use API for backup/import, Kasten for full state
- **Test security contexts** - OpenShift will reject non-compliant pods
- **Group-writable permissions** - required for arbitrary UID functionality