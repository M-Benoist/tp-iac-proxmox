output "web_vm_ip" {
  value = proxmox_virtual_environment_vm.vm_web.initialization[0].ip_config[0].ipv4[0].address
}

output "db_vm_ip" {
  value = proxmox_virtual_environment_vm.vm_db.initialization[0].ip_config[0].ipv4[0].address
}
