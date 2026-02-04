terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Network for the stack
resource "docker_network" "glpi_network" {
  name   = "glpi_network"
  driver = "overlay"
  attachable = true
}

# MariaDB Volume
resource "docker_volume" "mariadb_data" {
  name = "mariadb_data"
}

# GLPI Volumes
resource "docker_volume" "glpi_data" {
  name = "glpi_data"
}

resource "docker_volume" "glpi_plugins" {
  name = "glpi_plugins"
}

# Let's Encrypt Volume
resource "docker_volume" "letsencrypt_certs" {
  name = "letsencrypt_certs"
}

output "network_id" {
  value = docker_network.glpi_network.id
}

output "volumes" {
  value = {
    mariadb    = docker_volume.mariadb_data.name
    glpi_data  = docker_volume.glpi_data.name
    glpi_plugins = docker_volume.glpi_plugins.name
    letsencrypt = docker_volume.letsencrypt_certs.name
  }
}
