#!/bin/bash
# Deploy to Blue environment
# Usage: bash deploy-blue.sh <TAG>

set -e

TAG=$1

if [ -z "$TAG" ]; then
  echo "ERROR: TAG is required"
  echo "Usage: bash deploy-blue.sh <build-number>"
  exit 1
fi

echo "=============================="
echo " Deploying to BLUE environment"
echo " Image Tag: $TAG"
echo "=============================="

cd /opt/blue-green

# Export TAG so docker compose picks it up
export TAG=$TAG

# Pull latest images from Docker Hub
echo "--- Pulling latest images ---"
docker pull bhavyatank13/frontend-app:$TAG
docker pull bhavyatank13/backend-app:$TAG

# Stop and remove old blue containers if they exist
echo "--- Removing old blue containers ---"
docker compose -f docker-compose.blue.yml down --remove-orphans || true

# Start new blue containers
echo "--- Starting blue containers ---"
docker compose -f docker-compose.blue.yml up -d

echo "--- Blue environment started ---"
docker ps | grep blue || true

echo "=============================="
echo " Blue deployment done!"
echo " Frontend: http://APP_SERVER_IP:3001"
echo " Backend:  http://APP_SERVER_IP:5001"
echo "=============================="