# --- terraform/provider.tf ---

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1" # On fixe la version pour la stabilité
    }
  }
}

# On déclare les "boîtes" (variables)
# Terraform ira chercher les valeurs dans ton système (via les export TF_VAR_...)
variable "proxmox_api_url" {
  description = "L'URL de l'API Proxmox"
  type        = string
}

variable "proxmox_api_token" {
  description = "Le token complet (user@pve!id=secret)"
  type        = string
  sensitive   = true # Indispensable : masque la valeur dans tes terminaux
}

# On configure le fournisseur avec nos variables
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  
  # On active insecure car en Home Lab, on a rarement des certificats SSL officiels
  insecure  = true 

  # Optionnel mais recommandé : configurer SSH pour que Terraform puisse 
  # vérifier l'état des VMs après création
  ssh {
    agent = true
    # On peut aussi spécifier l'utilisateur ici si besoin
  }
}
