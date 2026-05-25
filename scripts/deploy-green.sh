#!/bin/bash
# Deploy to Green environment
# Usage: bash deploy-green.sh <TAG>

set -e

TAG=$1

if [ -z "$TAG" ]; then
  echo "ERROR: TAG is required"
  echo "Usage: bash deploy-green.sh <build-number>"
  exit 1
fi

echo "=============================="
echo " Deploying to GREEN environment"
echo " Image Tag: $TAG"
echo "=============================="

cd /opt/blue-green

export TAG=$TAG

echo "--- Pulling latest images ---"
docker pull bhavyatank13/frontend-app:$TAG
docker pull bhavyatank13/backend-app:$TAG

echo "--- Removing old green containers ---"
docker compose -f docker-compose.green.yml down --remove-orphans || true

echo "--- Starting green containers ---"
docker compose -f docker-compose.green.yml up -d

echo "--- Green environment started ---"
docker ps | grep green || true

echo "=============================="
echo " Green deployment done!"
echo " Frontend: http://APP_SERVER_IP:3002"
echo " Backend:  http://APP_SERVER_IP:5002"
echo "=============================="