#!/bin/bash

NAMESPACE="emqx"
BROKER="emqx-headless.emqx.svc.cluster.local"
PORT=1883

STEP_INTERVAL=$((15 * 60))  # 15 minutes in seconds
CLIENT_STEP=100             # Add 100 clients each step
MAX_CLIENTS=1000            # Maximum total clients

CURRENT_CLIENTS=100
LOAD_GENERATORS=()

echo "Starting EMQX load test..."
echo "Load increases every 15 minutes up to 1000 clients."
echo "-----------------------------------------------"

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

  # Stop if reached max clients
  if (( CURRENT_CLIENTS >= MAX_CLIENTS )); then
    echo "Reached max load: 1000 clients."
    break
  fi

  echo "Waiting 15 minutes before next load step..."
  sleep $STEP_INTERVAL

  CURRENT_CLIENTS=$((CURRENT_CLIENTS + CLIENT_STEP))

done

echo "Load test completed."
