terraform {
  required_providers {
      google = {
          source = "hashicorp/google"
          version = "3.5.0"
      }
  }
}

provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}

locals {
  worker_list = [for i in range(var.num_of_workers) : format("%s-%d", "worker", i+1)]

  k8s_vms = var.gvisor == "N" ? toset(concat(["master"], local.worker_list)) : (
    toset(concat(["master"], ["gvisor"], local.worker_list))
  )

  cni_provider =  var.cni_provider == "weavenet" ? (
      "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')") : (
      "https://docs.projectcalico.org/manifests/calico.yaml" )

  cluster_and_nw_install_script = templatefile("${path.module}/scripts/cluster_and_nw_install.sh", 
      { pod_cidr = var.pod_cidr, 
        service_cidr = var.service_cidr, 
        version = var.k8s_version,
        cni_provider = local.cni_provider})

  cri_version = join(".",slice(split(".",var.k8s_version),0,2))

  base_install_script = templatefile("${path.module}/scripts/base_install_script.sh", 
    { version = var.k8s_version, cri_version = local.cri_version })   

  gvisor_install_script = templatefile("${path.module}/scripts/gvisor_install.sh",
    { version = var.k8s_version })

  gcp_zone = join("-", [var.gcp_region, "a"])
}



resource "google_compute_network" "k8s-vnet-tf" {
  name = "k8s-vnet-tf"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet-10-1" {
  name = "subnet-tf-10-1"
  ip_cidr_range = "10.1.0.0/16"
  region = var.gcp_region
  network = google_compute_network.k8s-vnet-tf.id
  secondary_ip_range = [ {
    ip_cidr_range = var.pod_cidr
    range_name = "podips"
  },
  {
    ip_cidr_range = var.service_cidr
    range_name = "serviceips"
  } ]
}

resource "google_compute_firewall" "k8s-vnet-fw-external" {
    name = "k8s-vnet-fw-external"
    network = google_compute_network.k8s-vnet-tf.id
    allow {
      protocol = "tcp"
      ports = ["22","80","443", "30000-40000"]
    }

    allow {
      protocol = "icmp"
    }

    source_ranges = [ "0.0.0.0/0" ] 
}

resource "google_compute_firewall" "k8s-vnet-fw-internal" {
    name = "k8s-vnet-fw-internal"
    network = google_compute_network.k8s-vnet-tf.id
    allow {
      protocol = "tcp"
    }
    allow {
      protocol = "udp"
    }
    allow {
      protocol = "icmp"
    }
    allow {
      protocol = "ipip"
    }
    source_tags = [ "k8s" ] 
}

resource "google_compute_instance" "k8s-vms" {
    for_each = local.k8s_vms
    name = join("-",["k8s", each.key])
    machine_type = "n1-standard-2"
    zone = local.gcp_zone

    tags = [ "k8s", join("-",["k8s", each.key]) ]

    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
            size = 50
        }
  }

  network_interface {
    network = google_compute_network.k8s-vnet-tf.id
    subnetwork = google_compute_subnetwork.subnet-10-1.id
    access_config {
      // Allocate epheneral IP
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = each.key == "master" ? join("\n", 
      [local.base_install_script, local.cluster_and_nw_install_script]
      ) : ( each.key == "gvisor" ? local.gvisor_install_script : local.base_install_script )
}