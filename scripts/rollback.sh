#!/bin/bash
# Rollback to previous environment
# Usage: bash rollback.sh <blue|green>
# Example: if green is live and something broke, rollback to blue

ENV=$1

if [ -z "$ENV" ]; then
  # Auto-detect current active env and switch to opposite
  if [ -f /opt/blue-green/active-env ]; then
    CURRENT=$(cat /opt/blue-green/active-env)
    if [ "$CURRENT" = "blue" ]; then
      ENV="green"
    else
      ENV="blue"
    fi
    echo "Auto-detected current: $CURRENT → rolling back to: $ENV"
  else
    echo "ERROR: Cannot auto-detect. Specify blue or green."
    echo "Usage: bash rollback.sh <blue|green>"
    exit 1
  fi
fi

echo "=============================="
echo " ROLLBACK to: $ENV"
echo "=============================="

bash /opt/blue-green/scripts/switch.sh $ENV

echo "=============================="
echo " Rollback complete!"
echo " Traffic now pointing to: $ENV"
echo "=============================="