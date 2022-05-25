terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.9.0"
    }
  }

  terraform {
    cloud {
      organization = "mkaesz-dev"

      workspaces {
        name = "github-demo"
      }
    }
  }
}

variable "server_port" {
  description = "The server port"
  type        = number
}

provider "google" {
  project = "msk-pub"
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_instance" "vm" {
  name         = "vm0815"
  machine_type = "n1-standard-2"
  zone         = "europe-west3-a"
  hostname     = "vm0815.msk.pub"

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2110-impish-v20220505"
      size  = 12
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<EOT
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOT

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_firewall" "default" {
  name    = "firewall"
  network = data.google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["${var.server_port}"]
  }

  target_tags = ["web"]
}

module "bucket" {
  source      = "app.terraform.io/mkaesz-dev/bucket/gcp"
  version     = "1.0.0"
  bucket_name = "mkaesz-bucket-0987ztgbnkii7zgh"
}

output "web" {
  value = "${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}:${var.server_port}"
}
