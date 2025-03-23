# ab-test-lakehouse
Data Engineering Zoomcamp 2025 - Course Project

1. Start a GCP project. 
2. Copy `terraform.tfvars.example` file and rename it to `terraform.tfvars`. Put your project ID into it instead of "my-unique-project-id".
3. Run `terraform apply`

### Configuring Gravitino 
Catalog
gcloud compute ssh --project=project --zone=zone gravitino-instance
Start Gravitino as a standalone server using the configuration file located in ./conf.
/home/${username}/gravitino-0.8.0-incubating-bin/bin/gravitino.sh start

