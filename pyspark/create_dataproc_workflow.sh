#!/bin/bash

# ==== LOAD CONFIG ====
CONFIG_FILE="./dataproc.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file '$CONFIG_FILE' not found."
  exit 1
fi

# Load REGION, PROJECT_ID, DATAPROC_BUCKET
set -a
source "$CONFIG_FILE"
set +a

if [[ -z "$REGION" || -z "$PROJECT_ID" || -z "$DATAPROC_BUCKET" || -z "$DATAFLOW_BUCKET" ]]; then
  echo "REGION, PROJECT_ID, DATAPROC_BUCKET or DATAFLOW_BUCKET not defined in $CONFIG_FILE."
  exit 1
fi

# ==== SETTINGS ====
TEMPLATE_NAME="pyspark-funnel-ab-template"
CLUSTER_NAME="single-node-cluster"
SCRIPT_PATH="gs://${DATAPROC_BUCKET}/scripts"

echo "Using region: $REGION"
echo "Project ID: $PROJECT_ID"
echo "Dataproc bucket: $DATAPROC_BUCKET"
echo "Dataflow bucket: $DATAFLOW_BUCKET"

# ==== CREATE TEMPLATE ====
gcloud dataproc workflow-templates create "$TEMPLATE_NAME" \
  --region="$REGION"

# ==== CONFIGURE CLUSTER ====
gcloud dataproc workflow-templates set-managed-cluster "$TEMPLATE_NAME" \
  --region="$REGION" \
  --cluster-name="$CLUSTER_NAME" \
  --master-machine-type=n1-standard-2 \
  --num-workers=0 \
  --dataproc-metastore="projects/$PROJECT_ID/locations/$REGION/services/hive-metastore-ab25"

# ==== ADD JOBS ====
gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/json_txt_to_iceberg.py" \
  --step-id=json_txt_to_iceberg \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION" \
  --jars="gs://${DATAPROC_BUCKET}/binaries/iceberg-spark-runtime-3.5_2.12-1.8.1.jar" \
  -- \
  --base_path="gs://${DATAPROC_BUCKET}" \
  --json_bucket="gs://${DATAFLOW_BUCKET}"

gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/csv_to_iceberg.py" \
  --step-id=csv_to_iceberg \
  --start-after=json_txt_to_iceberg \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION" \
  --jars="gs://${DATAPROC_BUCKET}/binaries/iceberg-spark-runtime-3.5_2.12-1.8.1.jar" \
  -- \
  --base_path="gs://${DATAPROC_BUCKET}"

gcloud dataproc workflow-templates add-job pyspark "${SCRIPT_PATH}/ttest.py" \
  --step-id=ttest \
  --start-after=csv_to_iceberg \
  --workflow-template="$TEMPLATE_NAME" \
  --region="$REGION" \
  --jars="gs://${DATAPROC_BUCKET}/binaries/iceberg-spark-runtime-3.5_2.12-1.8.1.jar" \
  -- \
  --base_path="gs://${DATAPROC_BUCKET}"

# ==== CONFIRM ====
gcloud dataproc workflow-templates describe "$TEMPLATE_NAME" \
  --region="$REGION"

echo "Workflow template '$TEMPLATE_NAME' created in region '$REGION'."
