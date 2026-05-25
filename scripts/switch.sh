#!/bin/bash
# Switch Nginx traffic to blue or green
# Usage: bash switch.sh <blue|green>

ENV=$1

if [ "$ENV" = "blue" ]; then
  FRONTEND_PORT=3001
  BACKEND_PORT=5001
elif [ "$ENV" = "green" ]; then
  FRONTEND_PORT=3002
  BACKEND_PORT=5002
else
  echo "ERROR: specify blue or green"
  echo "Usage: bash switch.sh <blue|green>"
  exit 1
fi

echo "=============================="
echo " Switching Nginx to: $ENV"
echo " Frontend port: $FRONTEND_PORT"
echo " Backend port:  $BACKEND_PORT"
echo "=============================="

# Write new Nginx config
sudo tee /etc/nginx/sites-available/blue-green > /dev/null <<EOF
upstream frontend_active {
    server 127.0.0.1:${FRONTEND_PORT};
}

upstream backend_active {
    server 127.0.0.1:${BACKEND_PORT};
}

server {
    listen 80;
    server_name _;

    # Frontend — serve at /
    location / {
        proxy_pass http://frontend_active;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Backend API — serve at /api
    location /api/ {
        # Strip /api prefix before forwarding to backend
        rewrite ^/api(/.*)$ \$1 break;
        proxy_pass http://backend_active;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/blue-green /etc/nginx/sites-enabled/blue-green

# Remove default nginx site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx config
echo "--- Testing Nginx config ---"
sudo nginx -t

# Reload nginx (zero downtime)
echo "--- Reloading Nginx ---"
sudo systemctl reload nginx

# Save current active environment to a file
echo $ENV | sudo tee /opt/blue-green/active-env > /dev/null

echo "=============================="
echo " Nginx now pointing to: $ENV"
echo " Active env saved to: /opt/blue-green/active-env"
echo "=============================="