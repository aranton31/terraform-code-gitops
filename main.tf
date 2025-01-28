provider "google" {
  region = "asia-south1"
}

resource "google_compute_network" "gitops_vpc" {
  name                    = "devopsshack-vpc"
  auto_create_subnetworks = false

  description = "VPC network for GitOps Project"
}

resource "google_compute_subnetwork" "gitops_subnet" {
  count        = 2
  name         = "gitops-subnet-${count.index}"
  ip_cidr_range = cidrsubnet("10.0.0.0/16", 8, count.index)
  region       = "asia-south1"
  network      = google_compute_network.gitops_vpc.id
}

resource "google_compute_router" "gitops_router" {
  name    = "gitops-router"
  region  = "asia-south1"
  network = google_compute_network.gitops_vpc.id
}

resource "google_compute_router_nat" "gitops_nat" {
  name                              = "gitops-nat"
  router                            = google_compute_router.gitops_router.name
  region                            = "asia-south1"
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "gitops_allow_all" {
  name    = "gitops-allow-all"
  network = google_compute_network.gitops_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_container_cluster" "gitops" {
  name     = "gitops-cluster"
  location = "asia-south1"

  network    = google_compute_network.gitops_vpc.id
  subnetwork = google_compute_subnetwork.gitops_subnet[0].id

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}
}

resource "google_container_node_pool" "gitops" {
  name       = "gitops-node-pool"
  cluster    = google_container_cluster.gitops.name
  location   = google_container_cluster.gitops.location
  node_count = 3

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }
}
