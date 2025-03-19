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
  region  = "europe-west3" # Frankfurt, Germany
  zone    = "europe-west3-a"
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
