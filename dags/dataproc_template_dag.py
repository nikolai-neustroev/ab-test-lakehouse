
"""This DAG relies on an Airflow variable
https://airflow.apache.org/docs/apache-airflow/stable/concepts/variables.html
* project_id - Google Cloud Project ID to use for the Cloud Dataproc Template.
* region - Google Cloud Region to use for the Cloud Dataproc Template.
"""

import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocInstantiateWorkflowTemplateOperator,
)
from airflow.utils.dates import days_ago

project_id = "{{var.value.project_id}}"
region = "{{var.value.region}}"

default_args = {
    # Tell airflow to start one day ago, so that it runs as soon as you upload it
    "start_date": days_ago(1),
    "project_id": project_id,
}

with DAG(
    "dataproc_workflow_dag",
    default_args=default_args,
    schedule_interval=datetime.timedelta(days=1),
) as dag:
    start_template_job = DataprocInstantiateWorkflowTemplateOperator(
        task_id="dataproc_workflow_dag",
        template_id="pyspark-funnel-ab-template",
        project_id=project_id,
        region=region,
    )
