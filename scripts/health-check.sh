#!/bin/bash
# Health Check Script
# Usage: bash health-check.sh <blue|green>

ENV=$1
MAX_RETRIES=10
SLEEP_SECONDS=5

if [ "$ENV" = "blue" ]; then
  FRONTEND_PORT=3001
  BACKEND_PORT=5001
elif [ "$ENV" = "green" ]; then
  FRONTEND_PORT=3002
  BACKEND_PORT=5002
else
  echo "ERROR: specify blue or green"
  echo "Usage: bash health-check.sh <blue|green>"
  exit 1
fi

echo "=============================="
echo " Health Check: $ENV environment"
echo "=============================="

# Check frontend
echo "--- Checking Frontend (port $FRONTEND_PORT) ---"
for i in $(seq 1 $MAX_RETRIES); do
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:$FRONTEND_PORT | grep -q "200"; then
    echo "Frontend is healthy!"
    break
  fi
  echo "Attempt $i/$MAX_RETRIES — waiting..."
  sleep $SLEEP_SECONDS
  if [ $i -eq $MAX_RETRIES ]; then
    echo "FAILED: Frontend health check failed after $MAX_RETRIES attempts"
    exit 1
  fi
done

# Check backend
echo "--- Checking Backend (port $BACKEND_PORT) ---"
for i in $(seq 1 $MAX_RETRIES); do
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:$BACKEND_PORT/health | grep -q "200"; then
    echo "Backend is healthy!"
    break
  fi
  echo "Attempt $i/$MAX_RETRIES — waiting..."
  sleep $SLEEP_SECONDS
  if [ $i -eq $MAX_RETRIES ]; then
    echo "FAILED: Backend health check failed after $MAX_RETRIES attempts"
    exit 1
  fi
done

echo "=============================="
echo " Health check PASSED for $ENV"
echo "=============================="