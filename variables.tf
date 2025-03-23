variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "my-unique-project-id"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "GCP region zone"
  type        = string
  default     = "europe-west3-a"
}

variable "username" {
  description = "The username for the VM"
  type        = string
  default     = "your_username"
}