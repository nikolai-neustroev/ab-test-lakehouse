terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.27.0"
    }
  }
}

# Set project.
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

# Create the GCS bucket for the csv files and Spark binaries
# This bucket will be used to store the input files for the Dataproc job.
resource "google_storage_bucket" "dataproc_bucket" {
  name          = "dataproc-bucket-ab25"
  location      = var.region
  force_destroy = true
}

# Create a Pub/Sub topic.
resource "google_pubsub_topic" "events_topic" {
  name                       = "events-topic"
  message_retention_duration = "3600s"
}

# Create a Pub/Sub subscription attached to the topic.
resource "google_pubsub_subscription" "events_subscription" {
  name                       = "events-subscription"
  topic                      = google_pubsub_topic.events_topic.id
  message_retention_duration = "3600s"
}

# resource "google_compute_network" "net" {
#   name                    = "network-ab25"
#   auto_create_subnetworks = false
# }

resource "google_dataproc_metastore_service" "hive_metastore_ab25" {
  service_id          = "hive-metastore-ab25"
  location            = var.region
  tier                = "DEVELOPER"
  # network             = "projects/${var.project}/global/networks/${google_compute_network.net.id}"
  port                = 9083
  deletion_protection = false
}

resource "google_dataproc_cluster" "dataproc_cluster" {
  name    = "cluster-ab25"
  region  = var.region
  project = var.project

  cluster_config {
    staging_bucket = null

    endpoint_config {
      enable_http_port_access = true
    }

    gce_cluster_config {
      internal_ip_only = true
      service_account_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }

    metastore_config {
      dataproc_metastore_service = "projects/${var.project}/locations/${var.region}/services/hive-metastore-ab25"
    }

    master_config {
      num_instances = 1
      machine_type  = "n4-standard-2"
      disk_config {
        boot_disk_type    = "hyperdisk-balanced"
        boot_disk_size_gb = 100
      }
    }

    worker_config {
      num_instances = 2
      machine_type  = "n4-standard-2"
      disk_config {
        boot_disk_type    = "hyperdisk-balanced"
        boot_disk_size_gb = 200
      }
    }

    software_config {
      image_version       = "2.2-debian12"
      optional_components = ["FLINK"]
    }
  }
  depends_on = [ google_dataproc_metastore_service.hive_metastore_ab25 ]
}

/*
# Create the custom service account for Composer
resource "google_service_account" "composer_sa" {
  account_id   = "composer-sa"
  display_name = "Custom service account for Cloud Composer"
}

# Grant the service account the iam.serviceAccountUser role on the project.
# This role is required so that the Composer environment can act as this service account.
resource "google_project_iam_member" "composer_sa_iam" {
  project = var.project
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# Create the Cloud Composer environment, referencing the custom service account.
resource "google_composer_environment" "cloud_composer" {
  name   = "cloud-composer"
  region = var.region

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.composer_sa.email
    }

    software_config {
      image_version = "composer-3-airflow-2.10.2-build.11"

      env_variables = {
        VAR_NAME = "VAR_VALUE"
      }
    }
  }

  depends_on = [ google_project_iam_member.composer_sa_iam ]
}

# Create the GCS bucket for the Dataflow job
# This bucket will be used to store the output files from the Dataflow job.
resource "google_storage_bucket" "dataflow_bucket" {
  name          = "dataflow-bucket-ab25"
  location      = var.region
  force_destroy = true
}

# Create the Dataflow job
resource "google_dataflow_flex_template_job" "from_pubsub_to_csv_dfjob" {
  provider                = google-beta
  name                    = "from-pubsub-to-csv-dfjob"
  container_spec_gcs_path = "gs://dataflow-templates-europe-west3/latest/flex/Cloud_PubSub_to_GCS_Text_Flex"
  region                  = "europe-central2"

  parameters = {
    # inputTopic           = google_pubsub_topic.events_topic.id
    inputSubscription    = google_pubsub_subscription.events_subscription.id
    outputDirectory      = "gs://${google_storage_bucket.dataflow_bucket.name}/output/"
    userTempLocation     = "gs://${google_storage_bucket.dataflow_bucket.name}/temp"
    outputFilenamePrefix = "review-written-"
    outputFilenameSuffix = ".csv"
    outputShardTemplate  = "W-P-SS-of-NN"
    numShards            = "0"
    windowDuration       = "5m"
    yearPattern          = "-YYYY-"
    monthPattern         = "-MM-"
    dayPattern           = "-dd-"
    hourPattern          = "-HH-"
    minutePattern        = "-mm-"
    maxNumWorkers        = "2"
  }

  enable_streaming_engine = true
  additional_experiments  = ["streaming_mode_at_least_once"]
  labels                  = {}
}
*/
