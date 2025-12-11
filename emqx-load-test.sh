#!/bin/bash

NAMESPACE="emqx"
BROKER="emqx-headless.emqx.svc.cluster.local"
PORT=1883

STEP_INTERVAL=$((10 * 60))   # 10 minutes
CLIENT_STEP=100              # increase by 100 clients
MAX_CLIENTS=1000             # maximum 1000 clients

CURRENT_CLIENTS=100

echo "-------------------------------------------"
echo " EMQX LOAD TEST (Increase every 10 minutes)"
echo "-------------------------------------------"

while (( CURRENT_CLIENTS <= MAX_CLIENTS )); do

  JOB_NAME="bench-$CURRENT_CLIENTS"

  echo "Creating job: $JOB_NAME with $CURRENT_CLIENTS clients..."

  kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB_NAME
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: bench
        image: emqx/emqtt-bench
        args:
        - pub
        - -h
        - $BROKER
        - -p
        - "$PORT"
        - -c
        - "$CURRENT_CLIENTS"
        - --topic
        - load/%c
        - -q
        - "1"
        - -I
        - "1000"
        - -m
        - '{"PV":"15.7"}'
EOF

  echo "Job $JOB_NAME started."
  echo "Waiting 10 minutes before next step..."
  echo "-------------------------------------------"

  sleep $STEP_INTERVAL

  CURRENT_CLIENTS=$((CURRENT_CLIENTS + CLIENT_STEP))

done

echo "-------------------------------------------"
echo "Load test completed (1000 clients reached)."
echo "-------------------------------------------"
