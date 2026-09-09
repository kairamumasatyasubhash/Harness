# ============================================
# Creates:
# VPC + Public Subnet + Firewall + VM
#
# GCP Project : lhs-507905
# Region      : us-central1
# Zone        : us-central1-a
#
# State: Local
# No GCS backend
# ============================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ============================================
# GCP PROVIDER
# ============================================

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# ============================================
# VARIABLES
# ============================================

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "lhs-507905"
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# ============================================
# VPC NETWORK
# AWS VPC → GCP VPC Network
# ============================================

resource "google_compute_network" "demo" {
  name                    = "harness-demo-vpc"
  auto_create_subnetworks = false
}

# ============================================
# PUBLIC SUBNET
# AWS Subnet → GCP Subnetwork
# ============================================

resource "google_compute_subnetwork" "demo" {
  name          = "harness-demo-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.demo.id
}

# ============================================
# INTERNET ROUTE
# AWS Route Table → GCP Route
# ============================================

resource "google_compute_route" "internet" {
  name             = "harness-demo-internet-route"
  network          = google_compute_network.demo.name
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

# ============================================
# FIREWALL RULE
# AWS Security Group → GCP Firewall
#
# Allows TCP traffic from the internet.
# ============================================

resource "google_compute_firewall" "demo" {
  name    = "harness-demo-firewall"
  network = google_compute_network.demo.name

  allow {
    protocol = "tcp"
    ports = [
      "22",
      "80",
      "443"
    ]
  }

  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "harness-demo"
  ]
}

# ============================================
# COMPUTE ENGINE VM
# AWS EC2 → GCP Compute Engine
# ============================================

resource "google_compute_instance" "demo" {
  name         = "harness-demo-vm"
  machine_type = "e2-micro"
  zone         = var.gcp_zone

  tags = [
    "harness-demo"
  ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo.id

    access_config {
      # Creates an ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# ============================================
# OUTPUTS
# ============================================

output "vpc_id" {
  description = "GCP VPC Network ID"
  value       = google_compute_network.demo.id
}

output "subnet_id" {
  description = "GCP Subnetwork ID"
  value       = google_compute_subnetwork.demo.id
}

output "vm_public_ip" {
  description = "GCP VM Public IP"
  value       = google_compute_instance.demo.network_interface[0].access_config[0].nat_ip
}

output "vm_instance_id" {
  description = "GCP VM Instance ID"
  value       = google_compute_instance.demo.id
}