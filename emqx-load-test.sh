#!/bin/bash

NAMESPACE="emqx"
BROKER="emqx-headless.emqx.svc.cluster.local"
PORT=1883

STEP_INTERVAL=$((15 * 60))     # 15 minutes
CLIENT_STEP=100                # +100 clients each step
MAX_CLIENTS=1000               # stop at 1000 clients

CURRENT_CLIENTS=100

echo "-------------------------------------------"
echo "   EMQX 15-Min Step Load Generator"
echo "-------------------------------------------"
echo "Starting at 100 clients, adding 100 every 15 minutes."
echo "-------------------------------------------"

while (( CURRENT_CLIENTS <= MAX_CLIENTS )); do

  POD_NAME="emqtt-bench-$CURRENT_CLIENTS"

  echo "Starting load pod: $POD_NAME  with $CURRENT_CLIENTS clients..."

  kubectl run "$POD_NAME" \
    --image=emqx/emqtt-bench \
    -n $NAMESPACE \
    --restart=Never -- \
    pub -h $BROKER -p $PORT \
    -c $CURRENT_CLIENTS \
    --topic load/%c \
    -q 1 \
    -I 1000 \
    -m '{"PV":"15.7"}'

  echo "Pod $POD_NAME started."
  echo "Waiting 15 minutes before increasing load..."
  echo "-------------------------------------------"

  sleep $STEP_INTERVAL

  CURRENT_CLIENTS=$((CURRENT_CLIENTS + CLIENT_STEP))
done

echo "-------------------------------------------"
echo "Load test finished (max 1000 clients reached)."
echo "-------------------------------------------"
