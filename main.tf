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

resource "google_dataproc_metastore_service" "hive_metastore_ab25" {
  service_id          = "hive-metastore-ab25"
  location            = var.region
  tier                = "DEVELOPER"
  port                = 9083
  deletion_protection = false
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
  container_spec_gcs_path = "gs://dataflow-templates-europe-central2/latest/flex/Cloud_PubSub_to_GCS_Text_Flex"
  region                  = var.region

  parameters = {
    # inputTopic           = google_pubsub_topic.events_topic.id
    inputSubscription    = google_pubsub_subscription.events_subscription.id
    outputDirectory      = "gs://${google_storage_bucket.dataflow_bucket.name}/output/"
    userTempLocation     = "gs://${google_storage_bucket.dataflow_bucket.name}/temp"
    outputFilenamePrefix = "review-written-"
    outputFilenameSuffix = ".txt"
    outputShardTemplate  = "P-SS-of-NN"
    numShards            = "0"
    windowDuration       = "5m"
    maxNumWorkers        = "2"
  }

  enable_streaming_engine = true
  additional_experiments  = ["streaming_mode_at_least_once"]
  labels                  = {}
}
