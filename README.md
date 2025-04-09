# ab-test-lakehouse
Data Engineering Zoomcamp 2025 - Course Project

### Prerequisites
1. gcloud (Google Cloud SDK 509.0.0)
2. terraform (Terraform v1.11.2)

### Steps to reproduce
1. Start a new GCP project. 
2. Copy `terraform.tfvars.example` file and rename it to `terraform.tfvars`. Put your project ID into it instead of "my-unique-project-id".
3. Run `terraform apply`.
4. While the cloud infrastructure is emerging, generate mock data in ab-test-lakehouse-mock-data repo.
5. After Pub/Sub successfully created, send mock data review_written messages to it.
6. Upload remaining files to the dataproc_bucket, `csvs` folder.
7. In dataproc-bucket create `binaries` folder and upload [Iceberg binary](https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.8.1/iceberg-spark-runtime-3.5_2.12-1.8.1.jar) file.
8. In dataproc-bucket create `scripts` folder and upload *.py files from `pyspark` local folder.
9. In ./pyspark copy `dataproc.env.example` file to `dataproc.env` and set your variables.
10. Run `create_dataproc_workflow.sh`.
11. Go to [BigQuery](https://console.cloud.google.com/bigquery) and create a dataset named `dataset`.
12. Go to [Dataproc](https://console.cloud.google.com/dataproc/workflows/templates) and run the `pyspark-funnel-ab-template`.
13. After completion return to BigQuery and run `external_table.sql` query. Change the URI if required.
14. Go to [Looker Studio](https://lookerstudio.google.com/) and use tables from `dataset` as sources.

### Configuring Gravitino 
Catalog
gcloud compute ssh --project=project --zone=zone gravitino-instance
Start Gravitino as a standalone server using the configuration file located in ./conf.
/home/${username}/gravitino-0.8.0-incubating-bin/bin/gravitino.sh start

