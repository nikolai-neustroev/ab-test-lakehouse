# ab-test-lakehouse
Data Engineering Zoomcamp 2025 - Course Project

The ab-test-lakehouse project is a data engineering pipeline designed as part of the Data Engineering Zoomcamp 2025 course. It leverages Google Cloud Platform (GCP) services to process and analyze A/B testing data. The pipeline includes infrastructure provisioning with Terraform, data ingestion via Pub/Sub, data processing with Dataproc and PySpark, and data storage in BigQuery for further analysis and visualization.

### Data

I use mock data in this project. The data imitates user funnel events of an online store: homepage visit, product view, placing to cart, making an order, writing a review. [More here](https://github.com/nikolai-neustroev/ab-test-lakehouse-mock-data).

### Key Components

| **Component** | **Screenshot** |
|---|:---:|
| **Terraform** is used to provision GCP resources in IaC fashion |  |
| **Pub/Sub** is used for data streaming | f |
| **Dataflow** is used to ingest data from Pub/Sub and store in GCP bucket | f |
| **Apache Iceberg** is used as project's data lake. Data is partioned by experiment_uuid which ensures the uniform storage of the data | f |
| **Hive Metastore** is configured for Iceberg table management | f |
| **PySpark** scripts process data from CSV and JSON files, converting them into Iceberg tables | f |
| A workflow template orchestrates the execution of PySpark jobs on **Dataproc** | f |
| Processed data is stored in **BigQuery** and made accessible via an external Iceberg table and a native table | f |
| Results are visualized using **Looker Studio** | f |

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
