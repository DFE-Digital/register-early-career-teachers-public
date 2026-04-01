#!/bin/bash
set -e

# Konduit connections occassionally fail outside of our control
# Retry a command with exponential backoff
# Usage: ./retry-konduit.sh "command" "description"

COMMAND="$1"
DESCRIPTION="$2"
MAX_RETRIES="${MAX_RETRIES:-3}"
INITIAL_DELAY="${INITIAL_DELAY:-10}"

ATTEMPT=1
DELAY=$INITIAL_DELAY

while [ $ATTEMPT -le $MAX_RETRIES ]; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Attempt $ATTEMPT/$MAX_RETRIES: $DESCRIPTION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if eval "$COMMAND"; then
    echo "✅ $DESCRIPTION completed successfully"
    exit 0
  else
    EXIT_CODE=$?

    if [ $ATTEMPT -lt $MAX_RETRIES ]; then
      echo "❌ $DESCRIPTION failed with exit code $EXIT_CODE"
      echo "⏳ Waiting ${DELAY}s before retry (attempt $((ATTEMPT + 1))/$MAX_RETRIES)..."
      sleep $DELAY

      DELAY=$((DELAY * 2))  # Exponential backoff: 10s, 20s, 40s
      ATTEMPT=$((ATTEMPT + 1))
    else
      echo "❌ $DESCRIPTION failed after $MAX_RETRIES attempts"
      exit $EXIT_CODE
    fi

  fi
done
