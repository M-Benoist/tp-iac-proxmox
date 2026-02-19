# --- terraform/main.tf ---

locals {
  target_node = var.target_node
  template_id = var.template_id
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
        address = var.web_ip
        gateway = var.gateway
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
        address = var.db_ip
        gateway = var.gateway
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
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl", {
    # On retire le /24 de l'IP pour Ansible avec split
    web_ip = split("/", var.web_ip)[0],
    db_ip  = split("/", var.db_ip)[0]
  })
  filename = "../ansible/inventory.ini"
}
