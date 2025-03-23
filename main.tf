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

resource "google_compute_instance" "gravitino_instance" {
  name         = "gravitino-instance"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # Using Debian 11; change if needed
      size  = 20                       # Boot disk size in GB
    }
  }

  network_interface {
    network = "default"
    access_config {} # This allocates a public IP address
  }

  # Add tags to match the firewall rule for HTTP/HTTPS
  tags = ["http-server", "https-server"]

  metadata_startup_script = templatefile("${path.module}/gravitino_instance_startup.sh", {
    username = var.username
  })
}