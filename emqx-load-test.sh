#!/bin/bash

NAMESPACE="emqx"
BROKER="emqx-headless.emqx.svc.cluster.local"
PORT=1883

TOTAL_DURATION=900     # 15 minutes in seconds
STEP_INTERVAL=15       # Increase load every 15 seconds
CLIENT_STEP=100        # Add 100 clients each step
MAX_CLIENTS=1000       # Maximum total clients

CURRENT_CLIENTS=100
LOAD_GENERATORS=()

echo "Starting EMQX load test..."
echo "Total duration: 15 minutes"
echo "Load increases every 15 seconds up to 1000 clients."
echo "-----------------------------------------------"

START_TIME=$(date +%s)

while true; do

  echo "Starting load generator with $CURRENT_CLIENTS clients..."

  kubectl run -i --rm "emqtt-bench-$CURRENT_CLIENTS" \
    --image=emqx/emqtt-bench -n $NAMESPACE -- \
    pub -h $BROKER -p $PORT \
    -c $CURRENT_CLIENTS \
    --topic load/%c \
    -q 1 \
    -I 1000 \
    -m '{"PV":"15.7"}' &

  LOAD_GENERATORS+=($!)

  # Check time limit
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  if (( ELAPSED >= TOTAL_DURATION )); then
    echo "15 minutes reached. Stopping load test."
    kill ${LOAD_GENERATORS[@]} 2>/dev/null
    break
  fi

  # Stop if reached max clients
  if (( CURRENT_CLIENTS >= MAX_CLIENTS )); then
    echo "Reached max load: 1000 clients."
    sleep $((TOTAL_DURATION - ELAPSED))
    kill ${LOAD_GENERATORS[@]} 2>/dev/null
    break
  fi

  # Wait before next load increase
  sleep $STEP_INTERVAL
  CURRENT_CLIENTS=$((CURRENT_CLIENTS + CLIENT_STEP))

done

echo "Load test completed."
