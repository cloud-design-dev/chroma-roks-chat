# Multi-stage build for optimization
FROM --platform=$BUILDPLATFORM node:18-alpine AS build

WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage with nginx
FROM --platform=$BUILDPLATFORM nginx:alpine

# Create non-root user for OpenShift compatibility
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -D -S -G appuser appuser

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Create writable directories for nginx temp files and logs
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
    /tmp/uwsgi_temp /tmp/scgi_temp /tmp && \
    chown -R 1001:0 /tmp /usr/share/nginx/html /etc/nginx && \
    chmod -R g+rwX /tmp /usr/share/nginx/html /etc/nginx

# Custom nginx config for non-root and OpenShift
COPY nginx.conf /etc/nginx/nginx.conf

# Switch to non-root user
USER 1001

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
