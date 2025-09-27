# Multi-arch base image that works on both x86_64 and arm64 (M1 Mac)
FROM --platform=$BUILDPLATFORM python:3.12-slim

# Create non-root user for OpenShift compatibility
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash appuser

WORKDIR /app

# Install dependencies as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create data directory and set permissions for OpenShift arbitrary UID support
RUN mkdir -p /app/data && \
    chown -R 1001:0 /app && \
    chmod -R g+rwX /app

# Switch to non-root user
USER 1001

EXPOSE 8000

CMD ["python", "main.py"]