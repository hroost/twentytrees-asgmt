variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "ip_cidr_range" {
  description = "ip cidr range"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = regex("[a-z]+-[a-z0-9]+", var.region)
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.ip_cidr_range
}
