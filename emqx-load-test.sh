#!/bin/bash

NAMESPACE="emqx"
BROKER="emqx-headless.emqx.svc.cluster.local"
PORT=1883

STEP_INTERVAL=$((15 * 60))   # 15 minutes
CLIENT_STEP=100              # add 100 clients each step
MAX_CLIENTS=1000             # maximum clients

CURRENT_CLIENTS=100

echo "Starting EMQX load test..."
echo "Increasing load every 15 minutes up to $MAX_CLIENTS clients."
echo "-----------------------------------------------"

# Start initial pod
kubectl run emqtt-bench \
  --image=emqx/emqtt-bench -n $NAMESPACE --restart=Never -- \
  pub -h $BROKER -p $PORT \
  -c $CURRENT_CLIENTS \
  --topic load/%c \
  -q 1 \
  -I 1000 \
  -m '{"PV":"15.7"}' &

POD_NAME=$(kubectl get pods -n $NAMESPACE -l run=emqtt-bench -o jsonpath='{.items[0].metadata.name}')

while (( CURRENT_CLIENTS < MAX_CLIENTS )); do
  sleep $STEP_INTERVAL
  CURRENT_CLIENTS=$((CURRENT_CLIENTS + CLIENT_STEP))
  
  echo "Increasing clients in pod $POD_NAME to $CURRENT_CLIENTS..."

  # delete and restart pod with higher client count
  kubectl delete pod $POD_NAME -n $NAMESPACE --wait=true

  kubectl run emqtt-bench \
    --image=emqx/emqtt-bench -n $NAMESPACE --restart=Never -- \
    pub -h $BROKER -p $PORT \
    -c $CURRENT_CLIENTS \
    --topic load/%c \
    -q 1 \
    -I 1000 \
    -m '{"PV":"15.7"}' &

  POD_NAME=$(kubectl get pods -n $NAMESPACE -l run=emqtt-bench -o jsonpath='{.items[0].metadata.name}')
done

echo "Load test completed."
