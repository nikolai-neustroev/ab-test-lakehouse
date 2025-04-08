#!/bin/bash

# ==== LOAD CONFIG ====
CONFIG_FILE="./dataproc.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file '$CONFIG_FILE' not found."
  exit 1
fi

# Load REGION, PROJECT_ID, BUCKET
set -a
source "$CONFIG_FILE"
set +a

if [[ -z "$REGION" || -z "$PROJECT_ID" || -z "$BUCKET" ]]; then
  echo "REGION, PROJECT_ID, or BUCKET not defined in $CONFIG_FILE."
  exit 1
fi

# ==== SETTINGS ====
TEMPLATE_NAME="pyspark-funnel-ab-template"
CLUSTER_NAME="single-node-cluster"
SCRIPT_PATH="gs://${BUCKET}/scripts"

echo "Using region: $REGION"
echo "Project ID: $PROJECT_ID"
echo "Bucket: $BUCKET"

# ==== CREATE TEMPLATE ====
gcloud dataproc workflow-templates create "$TEMPLATE_NAME" \
  --region="$REGION"

# ==== CONFIGURE CLUSTER ====
gcloud dataproc workflow-templates set-managed-cluster "$TEMPLATE_NAME" \
  --region="$REGION" \
  --cluster-name="$CLUSTER_NAME" \
  --master-machine-type=n1-standard-2 \
  --num-workers=0

# ==== ADD JOBS ====
gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/job1.py" \
  --step-id=job1 \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION"

gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/job2.py" \
  --step-id=job2 \
  --start-after=job1 \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION"

gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/job3.py" \
  --step-id=job3 \
  --start-after=job2 \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION"

# ==== CONFIRM ====
gcloud dataproc workflow-templates describe "$TEMPLATE_NAME" \
  --region="$REGION"

echo "Workflow template '$TEMPLATE_NAME' created in region '$REGION'."
