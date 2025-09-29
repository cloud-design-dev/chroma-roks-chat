# Veeam Kasten ROKS Demo Guide: Animal Facts Chat App

## Demo Overview
This demo showcases Veeam Kasten's backup and restore capabilities for stateful applications running on Red Hat OpenShift on IBM Cloud (ROKS). We'll use an animal facts chat app with vector database storage to demonstrate disaster recovery scenarios.

## Demo Timeline

### 1. OpenShift Console Overview
- **Login to OpenShift UI** as cluster admin
- **Admin View**: Quickly show cluster resources, nodes, and overall health
- **Developer View**: Switch to developer perspective for application-focused view
- **Navigate to Project**: Go to `kasten-demo-chatapp` namespace

### 2. Application Architecture Review
- **Topology View**: Show the animal chat app components
  - Backend service (Python FastAPI)
  - Frontend service (React with Carbon Design)
  - Routes and service mesh connections
- **Builds**: Review BuildConfigs and recent builds from GitHub source
- **Deployments**: Show deployment status and pod health
- **Routes**: Display external access URLs

### 3. Application Functionality Demo
- **Access Application**: Click route URL to open chat app
- **Query Existing Facts**: Test searches like:
  - "Tell me about lions" 
  - "What can you tell me about elephants?"
  - "Facts about sharks"
- **Add New Facts**: Use the ➕ button to add custom animal facts
- **Show Stats**: Display current fact counts (28+ facts across 9+ species)

### 4. Simulate Data Loss Scenario
- **Delete Storage**: Remove the in-memory database backing storage
  - Scale backend deployment to 0 replicas
  - Or simulate database corruption
- **Verify Impact**: 
  - Refresh application page
  - Show error messages or empty responses
  - Demonstrate complete data loss

### 5. Kasten Dashboard & Restore Process

#### 5.1 Access Kasten Dashboard
- **Navigate to Kasten UI**: 
  - From OpenShift console: `Networking` → `Routes` → `kasten-io` namespace
  - Click on Kasten dashboard route URL
  - Or access via: `https://k10-route-kasten-io.apps.<cluster-domain>`

#### 5.2 Locate Application & Backup Policy
- **Applications Tab**: Click on "Applications" in left navigation
- **Find Namespace**: Locate `kasten-demo-chatapp` namespace
- **View Policy**: Click on associated backup policy `chatapp-backup-policy`
- **Policy Details**: Review:
  - Backup frequency (e.g., daily at 2 AM)
  - Retention settings (e.g., 30 days)
  - Last successful backup timestamp
  - Storage location (IBM Cloud Object Storage)

#### 5.3 Understanding Restore Points & Snapshots
- **Restore Points Tab**: Click "Restore Points" for the application
- **Snapshot Types**:
  - **Manual Snapshots**: On-demand backups triggered manually
  - **Scheduled Snapshots**: Automated backups from policy schedule
  - **Pre-hook Snapshots**: Taken before application changes
- **Restore Point Details**: Each restore point shows:
  - Timestamp of backup creation
  - Backup size and duration
  - Data consistency status
  - Associated Kubernetes resources
  - PVC snapshots and volume data

#### 5.4 Initiate Restore Process
- **Select Restore Point**: Choose the most recent successful backup
- **Click "Restore"**: Opens restore configuration wizard
- **Restore Options**:
  - **Restore Type**: 
    - Original location (same namespace)
    - Different namespace
    - Different cluster (for migration)
  - **Resource Selection**:
    - All resources (recommended)
    - Specific deployments only
    - Storage volumes only
  - **Advanced Options**:
    - Transform resources during restore
    - Apply resource filters
    - Override storage classes

#### 5.5 Configure Restore Settings
- **Target Namespace**: Select or create target namespace
- **Resource Conflicts**: Choose resolution strategy:
  - **Skip existing resources**
  - **Replace existing resources** (recommended for disaster recovery)
  - **Fail on conflicts**
- **Storage Options**:
  - **Use original storage class**
  - **Transform to different storage class**
  - **Restore to new PVCs**
- **Network Settings**:
  - Preserve original service configurations
  - Update routes and ingress if needed

#### 5.6 Execute & Monitor Restore
- **Start Restore**: Click "Restore" to begin process
- **Monitor Progress**: 
  - Real-time job status updates
  - Phase-by-phase progress (Preparing → Restoring → Finalizing)
  - Resource creation logs
  - Error messages if any issues occur
- **Estimated Time**: Typically 2-5 minutes for this demo app
- **Job Logs**: Detailed logging of each restore operation

### 6. OpenShift Resource Recreation
- **Watch Topology**: Monitor resources being recreated in real-time
- **Pod Status**: Show pods coming back online
- **Service Health**: Verify services are reconnecting
- **Route Availability**: Confirm external access is restored

### 7. Verify Complete Recovery
- **Access Restored App**: Navigate to application URL
- **Test Original Data**: Query for original facts to confirm data restoration
- **Verify Custom Facts**: Confirm previously added facts are restored
- **Show Statistics**: Display fact counts match pre-disaster state

## How Kasten Backup & Restore Works

### 🔧 **Backup Process Deep Dive**

#### Snapshot Creation
1. **Discovery Phase**:
   - Kasten scans namespace for all Kubernetes resources
   - Identifies persistent volumes and stateful components
   - Maps resource dependencies and relationships
   - Creates resource inventory for consistent backup

2. **Pre-Backup Hooks** (Optional):
   - Execute application-specific commands (e.g., database flush)
   - Quiesce application writes for consistency
   - Custom scripts for application preparation

3. **Volume Snapshot Creation**:
   - **CSI Integration**: Uses Container Storage Interface drivers
   - **Storage-Native Snapshots**: Leverages underlying storage capabilities
   - **Point-in-Time Consistency**: Atomic snapshot across all volumes
   - **Metadata Capture**: Stores PVC configurations and mount details

4. **Resource Export**:
   - **Kubernetes API Objects**: Deployments, Services, ConfigMaps, Secrets
   - **Custom Resources**: CRDs and operator-managed resources
   - **RBAC Objects**: ServiceAccounts, Roles, RoleBindings
   - **Network Policies**: Ingress rules and network configurations

5. **Data Protection**:
   - **Encryption**: AES-256 encryption for data at rest and in transit
   - **Compression**: Reduces backup storage footprint
   - **Deduplication**: Eliminates redundant data across backups
   - **Export to Object Storage**: Moves data to IBM Cloud Object Storage

### 🔄 **Restore Process Architecture**

#### Phase 1: Preparation & Validation
1. **Restore Point Selection**:
   - User selects specific backup timestamp
   - Kasten validates restore point integrity
   - Checks for required storage classes and dependencies
   - Verifies target namespace permissions

2. **Dependency Analysis**:
   - Maps resource creation order (ConfigMaps → Secrets → Deployments)
   - Identifies volume mount requirements
   - Resolves service mesh and network dependencies
   - Plans resource scheduling sequence

#### Phase 2: Storage Restoration
1. **PVC Recreation**:
   - Creates PersistentVolumeClaims with original specifications
   - Maps to available storage classes (with transformation if needed)
   - Initiates volume provisioning process

2. **Data Restoration**:
   - **From Volume Snapshots**: Direct storage-level restoration
   - **From Object Storage**: Downloads and streams data to new volumes
   - **Parallel Processing**: Restores multiple volumes simultaneously
   - **Progress Tracking**: Real-time status of data transfer

#### Phase 3: Application Restoration
1. **Kubernetes Resource Creation**:
   - **Namespace Setup**: Creates or validates target namespace
   - **ConfigMaps & Secrets**: Restores configuration data first
   - **Service Accounts**: Recreates RBAC and security contexts
   - **Services & Routes**: Restores network accessibility

2. **Workload Deployment**:
   - **Deployments**: Creates application pods with volume mounts
   - **StatefulSets**: Maintains ordered pod creation and persistent identity
   - **DaemonSets**: Ensures proper node-level service distribution
   - **Jobs & CronJobs**: Restores batch workload configurations

3. **Post-Restore Hooks** (Optional):
   - Execute application startup scripts
   - Validate data integrity
   - Perform application-specific recovery tasks
   - Health checks and readiness probes

### 📊 **Snapshot Management & Lifecycle**

#### Snapshot Types & Characteristics
- **Full Snapshots**: Complete application state capture
- **Incremental Snapshots**: Only changed data since last backup
- **Crash-Consistent**: Point-in-time storage state
- **Application-Consistent**: Coordinated with application state

#### Retention & Cleanup
- **Policy-Based Retention**: Automatic cleanup of old snapshots
- **Grandfather-Father-Son**: Tiered retention (daily/weekly/monthly)
- **Cross-Cloud Replication**: Geo-distributed backup copies
- **Immutable Storage**: WORM (Write-Once-Read-Many) compliance

#### Recovery Time & Point Objectives
- **RTO (Recovery Time Objective)**: 
  - Small apps (like demo): 2-5 minutes
  - Large applications: 15-30 minutes
  - Enterprise workloads: 1-2 hours
- **RPO (Recovery Point Objective)**: 
  - Last successful backup (typically 15 minutes to 24 hours)
  - Near-zero RPO with continuous data protection

### 🛠️ **Technical Implementation Details**

#### CSI Integration
```yaml
# Example VolumeSnapshot created by Kasten
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: chatapp-data-snapshot-20241226
spec:
  source:
    persistentVolumeClaimName: chatapp-data-pvc
  volumeSnapshotClassName: csi-snapshot-class
```

#### Backup Job Workflow
1. **Resource Discovery**: `kubectl get all,pvc,secrets,configmaps -n namespace`
2. **Volume Identification**: Scans for PVCs and associated pods
3. **Snapshot Creation**: Calls CSI driver snapshot APIs
4. **Metadata Export**: Serializes Kubernetes objects to JSON/YAML
5. **Data Export**: Streams volume data to object storage
6. **Verification**: Validates backup integrity and completeness

#### Restore Job Workflow
1. **Namespace Preparation**: Creates target namespace if needed
2. **PVC Restoration**: Recreates volumes from snapshots
3. **Resource Deployment**: Applies Kubernetes manifests in dependency order
4. **Volume Mounting**: Attaches restored volumes to new pods
5. **Service Activation**: Starts application services and routes
6. **Health Validation**: Runs readiness and liveness probes

### 🖥️ **Kasten UI Walkthrough - Step by Step**

#### Dashboard Overview
1. **Main Dashboard**: 
   - **Protection Status**: Green/Red indicators for backup health
   - **Recent Activity**: Timeline of backup and restore jobs
   - **Storage Usage**: Backup data consumption metrics
   - **Policy Compliance**: Percentage of protected applications

2. **Navigation Menu** (Left Sidebar):
   - **Applications**: View all discovered Kubernetes applications
   - **Policies**: Backup policies and schedules
   - **Jobs**: Running and completed backup/restore operations
   - **Profiles**: Storage locations and authentication
   - **Settings**: Global configuration and preferences

#### Applications Tab Deep Dive
1. **Application Discovery**:
   ```
   📱 kasten-demo-chatapp
   ├── 🔄 Compliant (Last backup: 2 hours ago)
   ├── 📊 Resources: 8 (Deployments, Services, ConfigMaps)
   ├── 💾 Storage: 2 PVCs (Total: 10Gi)
   └── 🛡️ Policy: chatapp-backup-policy
   ```

2. **Application Details View**:
   - **Resource Tree**: Hierarchical view of all Kubernetes objects
   - **Volume Information**: PVC details, storage class, usage
   - **Backup History**: Timeline of successful/failed backups
   - **Restore Points**: Available recovery options

#### Restore Point Selection Interface
1. **Restore Points List**:
   ```
   📅 2024-01-26 14:30:15 UTC  ✅ Success  📦 Scheduled  🔄 Ready
   📅 2024-01-26 02:00:12 UTC  ✅ Success  📦 Scheduled  🔄 Ready  
   📅 2024-01-25 14:30:18 UTC  ✅ Success  📦 Scheduled  🔄 Ready
   📅 2024-01-25 02:00:09 UTC  ⚠️  Warning 📦 Scheduled  ❌ Issues
   ```

2. **Restore Point Details**:
   - **Backup Size**: Data volume (e.g., "2.3 GB")
   - **Duration**: Time taken for backup (e.g., "4m 32s")
   - **Resources**: Count of Kubernetes objects backed up
   - **Volumes**: Number of PVCs included
   - **Export Status**: Object storage upload status

#### Restore Configuration Wizard
1. **Step 1: Basic Settings**
   ```
   🎯 Restore Target
   ├── 📂 Namespace: kasten-demo-chatapp (same as original)
   ├── 🔄 Restore Type: Replace existing resources
   └── ⚡ Priority: Standard
   ```

2. **Step 2: Resource Selection**
   ```
   ✅ All Resources (Recommended)
   ├── ✅ Deployments (2)
   ├── ✅ Services (2)  
   ├── ✅ ConfigMaps (3)
   ├── ✅ Secrets (1)
   ├── ✅ Routes (1)
   └── ✅ PersistentVolumeClaims (2)
   ```

3. **Step 3: Advanced Options**
   ```
   🔧 Transform Options
   ├── 💾 Storage Class: Keep original (ibmc-block-gold)
   ├── 🏷️  Labels: No changes
   ├── 🔀 Resource Mapping: Default
   └── 🔐 Security Context: Preserve original
   ```

4. **Step 4: Confirmation & Execution**
   ```
   📋 Restore Summary
   ├── 📅 Restore Point: 2024-01-26 14:30:15 UTC
   ├── 🎯 Target: kasten-demo-chatapp namespace
   ├── 📦 Resources: 11 Kubernetes objects
   ├── 💾 Volumes: 2 PVCs (10Gi total)
   └── ⏱️  Estimated Time: 3-5 minutes
   
   [Start Restore] [Cancel]
   ```

#### Live Restore Monitoring
1. **Job Progress Interface**:
   ```
   🔄 Restore Job: restore-chatapp-20240126-143045
   
   Progress: ████████████████████████████████████ 100%
   
   📊 Phases:
   ✅ Phase 1: Preparing namespace and resources
   ✅ Phase 2: Restoring persistent volumes  
   ✅ Phase 3: Creating Kubernetes objects
   ✅ Phase 4: Starting application pods
   ✅ Phase 5: Validating service health
   
   ⏱️  Duration: 4m 18s
   📦 Resources Created: 11/11
   💾 Volumes Restored: 2/2
   ```

2. **Real-Time Logs**:
   ```
   [14:30:45] Starting restore operation...
   [14:30:46] Creating target namespace: kasten-demo-chatapp
   [14:30:47] Restoring PVC: chatapp-backend-data
   [14:31:12] PVC ready, attaching to pods
   [14:31:15] Creating ConfigMap: chatapp-config
   [14:31:16] Creating Secret: chatapp-secrets
   [14:31:18] Creating Deployment: chatapp-backend
   [14:31:45] Backend pods ready (1/1)
   [14:32:02] Creating Deployment: chatapp-frontend  
   [14:32:28] Frontend pods ready (1/1)
   [14:32:30] Creating Service: chatapp-backend-service
   [14:32:31] Creating Service: chatapp-frontend-service
   [14:32:33] Creating Route: chatapp-route
   [14:33:01] Route ready, application accessible
   [14:34:03] Restore completed successfully! ✅
   ```

### 🚨 **Disaster Recovery Scenarios**

#### Scenario 1: Namespace Deletion
- **Problem**: Entire namespace accidentally deleted
- **Solution**: Full namespace restore from backup
- **Recovery Time**: 5-10 minutes
- **Data Loss**: Zero (last backup point)

#### Scenario 2: Database Corruption  
- **Problem**: Application data corrupted or lost
- **Solution**: Volume restore from clean backup
- **Recovery Time**: 3-5 minutes
- **Data Loss**: Changes since last backup

#### Scenario 3: Configuration Errors
- **Problem**: Bad deployment breaks application
- **Solution**: Selective resource restore
- **Recovery Time**: 2-3 minutes  
- **Data Loss**: None (data volumes preserved)

#### Scenario 4: Complete Cluster Failure
- **Problem**: Entire OpenShift cluster unavailable
- **Solution**: Cross-cluster restore to new environment
- **Recovery Time**: 15-30 minutes
- **Data Loss**: Zero (object storage backup)

## Veeam Kasten Backup & Restore Highlights

### 🔄 **Automated Backup Features**
- **Policy-Based Protection**: Set schedules and retention policies
- **Application-Aware Snapshots**: Consistent point-in-time captures
- **Cross-Cloud Portability**: Backup to object storage (IBM Cloud Object Storage)
- **Incremental Efficiency**: Only backup changed data blocks

### 🛡️ **Disaster Recovery Capabilities**
- **Granular Recovery**: Restore individual applications, namespaces, or clusters
- **Point-in-Time Recovery**: Choose specific backup snapshots
- **Cross-Cluster Restore**: Migrate applications between OpenShift clusters
- **Automated Testing**: Validate backup integrity with restore testing

### 📊 **Enterprise Management**
- **Centralized Dashboard**: Monitor backup status across multiple clusters
- **Compliance Reporting**: Track backup success rates and RTO/RPO metrics
- **RBAC Integration**: Role-based access control for backup operations
- **Alert & Notifications**: Proactive monitoring of backup health

### 🚀 **OpenShift Integration**
- **Native Kubernetes API**: Uses standard K8s resources and operators
- **CSI Snapshot Support**: Leverages Container Storage Interface
- **Operator Lifecycle**: Managed through OpenShift Operator Hub
- **Security Context**: Runs with minimal privileges using OpenShift SCCs

## Key Demo Talking Points

### **Business Value Propositions**
- **Zero Data Loss**: Complete application state recovery with RPO to last backup
- **Minimal Downtime**: Rapid restore process (minutes, not hours) - demonstrate RTO < 5 minutes
- **Operational Simplicity**: One-click backup and restore operations - no complex scripts
- **Cost Efficiency**: Pay only for storage used, not infrastructure overhead
- **Compliance Ready**: Meet regulatory requirements with automated retention policies
- **Risk Mitigation**: Protect against human error, ransomware, and infrastructure failures

### **Technical Advantages**
- **Container-Native**: Purpose-built for Kubernetes workloads, not adapted from VM solutions
- **Storage Agnostic**: Works with any CSI-compatible storage (IBM Block, File, Object)
- **Multi-Cloud Ready**: Consistent experience across cloud providers and hybrid environments
- **GitOps Friendly**: Declarative configuration management with Infrastructure as Code
- **API-First**: Full REST API for automation and integration with existing workflows
- **Kubernetes Native**: Uses CRDs, operators, and follows cloud-native principles

### **Competitive Differentiators**
- **Application-Centric**: Understands Kubernetes application relationships and dependencies
- **Cross-Namespace Awareness**: Handles complex applications spanning multiple namespaces
- **Transformation Capabilities**: Restore to different clusters with resource modifications
- **Incremental Forever**: Efficient storage utilization with smart deduplication
- **Immutable Backups**: WORM compliance and protection against tampering
- **Mobility & Portability**: Move applications between clusters, clouds, and environments

### **OpenShift Specific Benefits**
- **Security Context Compatibility**: Works with OpenShift's strict security constraints
- **Operator Hub Integration**: Easy installation and lifecycle management
- **Route & Service Mesh Support**: Full understanding of OpenShift networking
- **RBAC Integration**: Respects OpenShift's role-based access control
- **Red Hat Partnership**: Certified and supported on Red Hat OpenShift

### **Demo Flow Timing & Best Practices**

#### **Optimal Demo Duration**: 15-20 minutes total
```
⏱️  Demo Segment Breakdown:
├── 📋 OpenShift Overview (2-3 minutes)
├── 🎮 Application Demo (3-4 minutes)  
├── 💥 Disaster Simulation (1-2 minutes)
├── 🔄 Kasten Restore Process (5-7 minutes)
├── ✅ Recovery Validation (2-3 minutes)
└── 💬 Q&A Discussion (3-5 minutes)
```

#### **Presentation Tips**
1. **Start with Impact**: Show working application first, don't explain technology upfront
2. **Create Suspense**: Build up to the "disaster" moment for dramatic effect  
3. **Live Commentary**: Narrate what's happening during restore process
4. **Show, Don't Tell**: Let the UI and process speak for themselves
5. **Prepare Fallbacks**: Have screenshots ready in case of connectivity issues

#### **Audience Engagement Strategies**
- **Ask Questions**: "What would happen to your business if this application went down?"
- **Relate to Experience**: "How long do your current restores take?"
- **Quantify Benefits**: "This just saved us 4 hours compared to traditional backup methods"
- **Highlight Automation**: "No manual intervention required - this could run at 3 AM"

### **Common Objections & Responses**

#### **"We already have Velero/other backup solution"**
**Response**: 
- Velero is infrastructure-focused; Kasten is application-aware
- Kasten provides transformation capabilities during restore
- Better user experience with visual dashboard and policy management
- Enterprise features like compliance reporting and multi-tenancy

#### **"Our applications are stateless"**
**Response**:
- Configurations, secrets, and custom resources still need protection
- Application mobility between environments requires full state capture
- Disaster recovery includes more than just data - it's entire application stack
- Demonstrate with ConfigMaps, Routes, and service configurations

#### **"Cloud provider handles backups"**
**Response**:
- Cloud backups are infrastructure-level, not application-aware
- No cross-cloud portability or multi-cluster mobility
- Limited granular recovery options
- Vendor lock-in vs. portable solution

#### **"We use GitOps for everything"**
**Response**:
- GitOps handles deployment, not runtime state and data
- Secrets and dynamic configurations not stored in Git
- GitOps recovery is slower and requires manual intervention
- Kasten complements GitOps by protecting runtime state

### **ROI Calculations & Metrics**

#### **Downtime Cost Savings**
```
Traditional Recovery: 4-8 hours × $50,000/hour = $200,000-$400,000
Kasten Recovery: 5 minutes × $50,000/hour = $4,167
Savings per incident: $195,833-$395,833
```

#### **Operational Efficiency**
```
Traditional backup management: 20 hours/week × $100/hour = $2,000/week
Kasten automation: 2 hours/week × $100/hour = $200/week
Annual savings: $93,600
```

#### **Storage Optimization**
```
Traditional full backups: 100GB × 30 days = 3TB/month
Kasten incremental: 100GB + (10GB × 29) = 390GB/month
Storage savings: 87% reduction in backup storage costs
```

## Troubleshooting & Common Issues

### 🔧 **Restore Process Issues**

#### Issue 1: Restore Job Fails at Volume Creation
**Symptoms**: 
- Restore stuck at "Creating PVCs" phase
- Error: "StorageClass not found" or "Insufficient storage"

**Root Causes**:
- Target cluster lacks required storage class
- Storage quota exceeded in target namespace
- CSI driver not properly configured

**Solutions**:
1. **Check Storage Classes**: `kubectl get storageclass`
2. **Verify Quotas**: `kubectl describe quota -n target-namespace`
3. **Transform Storage Class**: Use Kasten's transform feature
4. **Update Cluster**: Install required CSI drivers

```bash
# Example: Check available storage classes
kubectl get storageclass
NAME                         PROVISIONER       AGE
ibmc-block-bronze           ibm.io/ibmc-block  30d
ibmc-block-silver           ibm.io/ibmc-block  30d
ibmc-block-gold (default)   ibm.io/ibmc-block  30d
```

#### Issue 2: Pod Startup Failures After Restore
**Symptoms**:
- Pods stuck in `Pending` or `CrashLoopBackOff` state  
- Application not accessible after restore completes

**Root Causes**:
- SecurityContext incompatibilities
- Missing ServiceAccount permissions
- Volume mount issues
- Resource limits/requests mismatch

**Solutions**:
1. **Check Pod Events**: `kubectl describe pod <pod-name> -n <namespace>`
2. **Review Security Contexts**: Verify SCC assignments
3. **Validate Volume Mounts**: Check PVC binding status
4. **Update Resource Limits**: Adjust CPU/memory if needed

```bash
# Debug pod issues
kubectl get pods -n kasten-demo-chatapp
kubectl describe pod chatapp-backend-xxx -n kasten-demo-chatapp
kubectl logs chatapp-backend-xxx -n kasten-demo-chatapp
```

#### Issue 3: Network/Route Accessibility Problems
**Symptoms**:
- Restore completes successfully but app not reachable
- Route exists but returns 503/404 errors

**Root Causes**:
- Service endpoints not ready
- Route target service mismatch  
- Network policies blocking traffic
- Load balancer configuration issues

**Solutions**:
1. **Check Service Endpoints**: `kubectl get endpoints -n <namespace>`
2. **Verify Route Configuration**: `kubectl describe route -n <namespace>`
3. **Test Internal Connectivity**: Pod-to-pod communication
4. **Review Network Policies**: Ensure traffic allowed

```bash
# Debug network issues
kubectl get svc,endpoints,routes -n kasten-demo-chatapp
curl -I http://chatapp-route-url/api/stats
kubectl exec -it <frontend-pod> -- curl http://chatapp-backend-service:8000/api/stats
```

#### Issue 4: Backup Integrity Problems
**Symptoms**:
- Restore point appears corrupted
- Partial data recovery or inconsistent state

**Root Causes**:
- Backup interrupted during creation
- Storage system issues during backup
- Network problems during export
- Application was not quiesced properly

**Solutions**:
1. **Use Earlier Restore Point**: Select previous successful backup
2. **Verify Backup Integrity**: Run Kasten validation
3. **Check Export Logs**: Review backup job details
4. **Implement Pre-Backup Hooks**: Ensure application consistency

### 🔍 **Kasten Dashboard Troubleshooting**

#### Issue: Kasten UI Not Accessible
**Solutions**:
1. **Check Route Status**: `kubectl get route -n kasten-io`
2. **Verify Pod Health**: `kubectl get pods -n kasten-io`
3. **Review Gateway Config**: Check Kasten gateway service
4. **Network Connectivity**: Test from local machine

#### Issue: Application Not Showing in Dashboard
**Solutions**:
1. **Trigger Discovery**: Force application scan
2. **Check Annotations**: Verify namespace labels
3. **Review RBAC**: Ensure Kasten has proper permissions
4. **Restart Controller**: Restart Kasten catalog service

#### Issue: Backup Policy Not Executing
**Solutions**:
1. **Check Schedule**: Verify cron expression syntax
2. **Review Job Logs**: Look for execution errors
3. **Validate Storage Profile**: Test object storage connectivity
4. **Resource Constraints**: Ensure sufficient cluster resources

### 📊 **Pre-Demo Validation Checklist**

#### Kasten Environment Check
- [ ] Kasten dashboard accessible via route
- [ ] All Kasten pods running and healthy
- [ ] Storage profiles configured and tested
- [ ] Backup policies active and successful

#### Application Environment Check  
- [ ] Demo app deployed and functional
- [ ] All pods running (backend + frontend)
- [ ] Route accessible from external network
- [ ] Database populated with expected facts
- [ ] Add fact functionality working

#### Backup Readiness Check
- [ ] Recent successful backup available (< 4 hours old)
- [ ] Backup includes all required resources
- [ ] Object storage connectivity verified
- [ ] Restore point integrity validated

#### Demo Script Preparation
- [ ] Test queries prepared ("lions", "elephants", etc.)
- [ ] Custom facts ready to add during demo
- [ ] Data destruction method identified
- [ ] Expected restore time documented (3-5 minutes)
- [ ] Validation steps defined for post-restore

### ⚡ **Quick Recovery Commands**

#### Emergency Restore (CLI)
```bash
# List available restore points
kubectl get restorepoint -n kasten-demo-chatapp

# Create restore job
kubectl apply -f - <<EOF
apiVersion: actions.kio.kasten.io/v1alpha1
kind: RestoreAction
metadata:
  name: emergency-restore
spec:
  subject:
    name: kasten-demo-chatapp
    namespace: kasten-demo-chatapp
  restorePoint: restore-point-name
EOF

# Monitor restore progress
kubectl get restoreaction emergency-restore -w
```

#### Application Health Check
```bash
# Quick status check
kubectl get pods,svc,routes -n kasten-demo-chatapp
curl -s http://chatapp-route-url/api/stats | jq .
```

## Success Metrics
- **Recovery Time Objective (RTO)**: < 5 minutes
- **Recovery Point Objective (RPO)**: Last successful backup
- **Data Integrity**: 100% fact recovery validation
- **Application Availability**: Full functionality restored

---

*This demo showcases enterprise-grade data protection for mission-critical applications running on Red Hat OpenShift with IBM Cloud.*