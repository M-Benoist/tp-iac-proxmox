# --- terraform/main.tf ---

locals {
  target_node = "srv-pve-01" # <<-- Ton nom de noeud vérifié tout à l'heure
  template_id = 9000  # <<-- L'ID de ton template Cloud-Init
  ssh_key     = trimspace(file("~/.ssh/id_ed25519.pub"))
}

# VM WEB
resource "proxmox_virtual_environment_vm" "vm_web" {
  name      = "vm-web-tp"
  node_name = local.target_node
  vm_id     = 302

# On force Terraform à attendre un peu et à démarrer la VM
  started = true

  clone {
    vm_id = local.template_id
# Optionnel mais recommandé : 
    full = true
  }

  initialization {
# AJOUTE CE BLOC DNS
    dns {
      servers = ["1.1.1.1", "8.8.8.8"] # DNS Cloudflare et Google
    }
# Assure-toi que cette section est bien là
    datastore_id = "vmstorage" # <<-- REMPLACE PAR TON NOM DE STOCKAGE

    ip_config {
      ipv4 {
        address = "192.168.50.242/24"
        gateway = "192.168.50.1"
      }
    }
    user_account {
      username = "deploy"
      keys     = [local.ssh_key]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}

# VM DATABASE
resource "proxmox_virtual_environment_vm" "vm_db" {
  name      = "vm-db-tp"
  node_name = local.target_node
  vm_id     = 303

# On force Terraform à attendre un peu et à démarrer la VM
  started = true

  clone {
    vm_id = local.template_id
# Optionnel mais recommandé : 
    full = true
  }

  initialization {
# AJOUTE CE BLOC DNS
    dns {
      servers = ["1.1.1.1", "8.8.8.8"] # DNS Cloudflare et Google
    }
# Assure-toi que cette section est bien là
    datastore_id = "vmstorage" # <<-- REMPLACE PAR TON NOM DE STOCKAGE
    ip_config {
      ipv4 {
        address = "192.168.50.241/24"
        gateway = "192.168.50.1"
      }
    }
    user_account {
      username = "deploy"
      keys     = [local.ssh_key]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}
