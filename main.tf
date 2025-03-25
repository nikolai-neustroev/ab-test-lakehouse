terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# Set project.
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
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

# resource "google_compute_instance" "gravitino_instance" {
#   name         = "gravitino-instance"
#   machine_type = "e2-standard-4"
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11" # Using Debian 11; change if needed
#       size  = 20                       # Boot disk size in GB
#     }
#   }

#   network_interface {
#     network = "default"
#     access_config {} # This allocates a public IP address
#   }

#   # Add tags to match the firewall rule for HTTP/HTTPS
#   tags = ["http-server", "https-server"]

#   metadata_startup_script = templatefile("${path.module}/gravitino_instance_startup.sh", {
#     username = var.username
#   })
# }

# resource "google_compute_firewall" "allow_http_https" {
#   name    = "allow-http-https"
#   network = "default"

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }

#   target_tags = ["http-server", "https-server"]
# }

resource "google_dataproc_metastore_service" "hive_metastore_61ea" {
  service_id          = "hive-metastore-61ea"
  location            = var.region
  tier                = "DEVELOPER"
  network             = "default"
  port                = 9083
  release_channel     = "STABLE"
  deletion_protection = false

  # If you need to configure a maintenance window, add the following block:
  # maintenance_window {
  #   day_of_week = "MONDAY"   # Replace with desired day or remove block for "any window"
  #   hour_of_day = 0
  # }

  # To use customer-managed encryption keys, uncomment and configure the block below:
  # encryption_config {
  #   kms_key = "projects/my-project/locations/global/keyRings/my-keyring/cryptoKeys/my-key"
  # }

  # Data Catalog integration can be configured via the metadata_integration block if needed:
  # metadata_integration {
  #   enabled = false
  # }
}

resource "google_dataproc_cluster" "dataproc_cluster" {
  name    = "cluster-fd25"
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
      # dataproc_metastore_service = google_dataproc_metastore_service.hive_metastore_61ea.id
      dataproc_metastore_service = "projects/${var.project}/locations/${var.region}/services/hive-metastore-61ea"
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
}

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
    }
  }
}
