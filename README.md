# ab-test-lakehouse
Data Engineering Zoomcamp 2025 - Course Project

### Prerequisites
1. gcloud (Google Cloud SDK 509.0.0)
2. terraform (Terraform v1.11.2)

### Steps
1. Start a new GCP project. 
2. Copy `terraform.tfvars.example` file and rename it to `terraform.tfvars`. Put your project ID into it instead of "my-unique-project-id".
3. Run `terraform apply`.
4. While the cloud infrastructure is emerging, generate mock data in ab-test-lakehouse-mock-data repo.
5. After Pub/Sub successfully created, send mock data review_written messages to it.
6. Upload remaining files to the dataproc_bucket.
7. Upload iceberg-spark-runtime file to the dataproc_bucket.
8. In dataproc-bucket create `binaries` folder and upload [Iceberg binary](https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.8.1/iceberg-spark-runtime-3.5_2.12-1.8.1.jar) file.
9. Go to [Google Cloud Composer](https://console.cloud.google.com/composer/).
- Upload `pyspark/json_txt_to_iceberg.py` to dataproc_bucket/pyspark_job_files.
10. Open cloud-composer environment and go to the "DAGS" section.
11. Press "OPEN DAGS FOLDER".
12. Upload `dags/json_txt_to_iceberg_dag.py`.

### Configuring Gravitino 
Catalog
gcloud compute ssh --project=project --zone=zone gravitino-instance
Start Gravitino as a standalone server using the configuration file located in ./conf.
/home/${username}/gravitino-0.8.0-incubating-bin/bin/gravitino.sh start

