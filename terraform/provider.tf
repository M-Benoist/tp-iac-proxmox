# --- terraform/provider.tf ---

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true # À garder si ton certificat Proxmox est auto-signé
}

# Déclaration des variables de connexion (remplies par ton .tfvars)
variable "proxmox_api_url" { type = string }
variable "proxmox_api_token" { type = string }
