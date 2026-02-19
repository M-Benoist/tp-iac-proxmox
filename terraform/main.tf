# --- terraform/main.tf ---

locals {
  target_node = var.target_node
  template_id = var.template_id
  ssh_key     = trimspace(file("~/.ssh/id_ed25519.pub"))
}

# VM WEB
resource "proxmox_virtual_environment_vm" "vm_web" {
  name      = "vm-web-${var.env}" # <- Dynamique
  node_name = local.target_node
  vm_id     = var.web_vm_id       # <- Dynamique
  started = true

  clone {
    vm_id = local.template_id
    full = true
  }

  disk {
    datastore_id = "vmstorage" 
    interface    = "scsi0"
    size         = 10
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"] # DNS Cloudflare et Google
    }
    datastore_id = "vmstorage"
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
  name      = "vm-db-${var.env}" # <- Dynamique
  node_name = local.target_node
  vm_id     = var.db_vm_id       # <- Dynamique
  started = true

  clone {
    vm_id = local.template_id
    full = true
  }

  disk {
    datastore_id = "vmstorage"
    interface    = "scsi0"
    size         = 10
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    datastore_id = "vmstorage"
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
    web_ip = split("/", var.web_ip)[0],
    db_ip  = split("/", var.db_ip)[0],
    env    = var.env
  })
  filename = "../ansible/environments/${var.env}/inventory.ini"
}
