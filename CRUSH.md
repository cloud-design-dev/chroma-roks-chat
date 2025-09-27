# CRUSH.md - Kasten ROKS Demo Chat App

## Project Overview
Vector database-backed chat app for animal facts demo with Python backend, Node/React frontend, and IBM Carbon Design System.

## ✨ Key Features
- ⚡ **UV Package Manager**: Ultra-fast Python package installation (10-100x faster than pip)  
- 🔒 **Virtual Environment**: Proper isolation, eliminates root user warnings
- 📊 **Performance**: Package resolution in 283ms, installation in 36ms
- 🛡️ **OpenShift Compatible**: Non-root user, security contexts, arbitrary UIDs
- 🎨 **Visual Appeal**: Animal emojis and IBM Carbon Design System
- 📈 **Kasten Ready**: Backup policies and restore demonstrations

## OpenShift Deployment
```bash
# Option 1: Build from GitHub source (ready to use)
./openshift/deploy-from-github.sh

# Option 2: Use different branch
./openshift/deploy-from-github.sh https://github.com/cloud-design-dev/chroma-roks-chat.git feature-branch

# Manual deployment steps
oc apply -f openshift/build-configs.yaml    # Builds from GitHub
oc start-build chatapp-backend-build --follow
oc start-build chatapp-frontend-build --follow
oc apply -f openshift/backend.yaml
oc apply -f openshift/frontend.yaml
oc apply -f openshift/kasten-policy.yaml

# Get application URL
oc get route chatapp-route -n kasten-demo-chatapp

# Check deployment status
oc get pods -n kasten-demo-chatapp
oc logs -l component=backend -n kasten-demo-chatapp -f
```

## Code Style Guidelines
- **Python**: Follow PEP 8, use type hints, async/await for I/O operations
- **JavaScript/React**: Use ES6+, functional components with hooks, TypeScript preferred
- **UI/UX**: IBM Carbon Design System components and patterns
- **Naming**: snake_case (Python), camelCase (JS), PascalCase (React components)
- **Imports**: Group by standard library, third-party, local modules
- **Error Handling**: Use proper exception handling, log errors appropriately
- **Vector DB**: Research-driven choice between top containerized options
- **API**: RESTful endpoints, proper HTTP status codes
- **Docker**: Multi-stage builds for production optimization