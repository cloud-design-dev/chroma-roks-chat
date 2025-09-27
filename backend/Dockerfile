# Multi-arch base image that works on both x86_64 and arm64 (M1 Mac)
FROM --platform=$BUILDPLATFORM python:3.12-slim

# Install uv - fast Python package installer and resolver
RUN pip install uv

# OpenShift compatibility - no hardcoded user needed

WORKDIR /app

# Copy requirements file first (for better Docker layer caching)
COPY requirements.txt .

# Create virtual environment and install dependencies using uv
RUN uv venv /app/.venv --python /usr/local/bin/python3.12 && \
    uv pip install -r requirements.txt

# Copy application files
COPY . .

# Create data directory and set permissions for OpenShift arbitrary UID support
RUN mkdir -p /app/data && \
    chown -R 0:0 /app && \
    chmod -R g+rwX /app

# OpenShift will run with arbitrary UID, no explicit USER needed

# Activate virtual environment and set PATH
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

EXPOSE 8000

CMD ["python", "main.py"]