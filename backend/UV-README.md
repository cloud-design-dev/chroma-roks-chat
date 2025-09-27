# Backend Container with UV Virtual Environment

## ✨ Updated Dockerfile Features

The backend now uses `uv` (ultra-fast Python package installer) with a proper virtual environment:

### Key Improvements:
- ⚡ **Ultra-fast installs**: `uv` is 10-100x faster than pip
- 🔒 **Virtual environment**: Isolated dependencies, no root warnings
- 🛡️ **OpenShift compatible**: Non-root user (1001), proper permissions
- 📦 **Better caching**: Improved Docker layer caching
- 🔄 **Multi-arch support**: Works on x86_64 and ARM64 (M1 Mac)

### Performance Comparison:
- **Before (pip)**: ~30-60 seconds for package installation
- **After (uv)**: ~3-4 seconds for package installation  
- **Package resolution**: 283ms vs several seconds with pip
- **Installation**: 36ms vs several seconds with pip

## 🏗️ How It Works

### Virtual Environment Setup:
```dockerfile
# Install uv
RUN pip install uv

# Create virtual environment with uv (much faster than python -m venv)
RUN uv venv /app/.venv --python /usr/local/bin/python3.12 && \
    uv pip install -r requirements.txt

# Activate virtual environment
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
```

### OpenShift Compatibility:
- ✅ Runs as non-root user (UID 1001)
- ✅ Group-writable permissions for arbitrary UIDs
- ✅ No privilege escalation required
- ✅ Security contexts compatible with OpenShift SCCs

## 📊 Build Output Comparison

### Before (pip):
```
Successfully installed annotated-types-0.7.0 anyio-3.7.1...
WARNING: Running pip as the 'root' user can result in broken permissions...
```

### After (uv + venv):
```
Using CPython 3.12.11 interpreter at: /usr/local/bin/python3.12
Creating virtual environment at: .venv
Resolved 27 packages in 283ms
Installed 27 packages in 36ms
```

No warnings, much faster, cleaner output!

## 🚀 Deployment Impact

### Local Development:
- Faster Docker builds during development
- Consistent environment between local and production
- No dependency conflicts

### OpenShift Deployment:
- Faster image builds from GitHub source
- More reliable builds (uv handles dependency resolution better)
- Smaller attack surface (isolated virtual environment)

### Kasten Backup/Restore:
- Same functionality and data persistence
- Faster container startup after restore
- More reliable application state

## 🔧 Usage

The application works exactly the same - all the API endpoints and functionality remain unchanged:

```bash
# Build and test locally
docker-compose up --build

# Deploy to OpenShift (unchanged commands)
./openshift/quick-deploy.sh

# Import database (unchanged)
./openshift/import-database.sh backup.json
```

## 📝 Technical Details

### Virtual Environment Location:
- **Path**: `/app/.venv`
- **Activation**: Automatic via ENV variables
- **Isolation**: Complete package isolation
- **Permissions**: Non-root compatible

### Package Management:
- **Resolver**: uv's Rust-based resolver
- **Cache**: Aggressive caching for faster subsequent builds
- **Lockfile**: Compatible with pip-tools workflows
- **Standards**: Fully compatible with pip and PyPI

The virtual environment ensures your Kasten demo app runs in a clean, isolated environment with blazing-fast build times!