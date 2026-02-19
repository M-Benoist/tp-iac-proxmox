variable "proxmox_api_url" { type = string }
variable "proxmox_api_token" { type = string }
variable "target_node" { default = "srv-pve-01" }
variable "template_id" { default = 9000 }
variable "web_ip" { default = "192.168.50.242/24" }
variable "db_ip" { default = "192.168.50.241/24" }
variable "gateway" { default = "192.168.50.1" }
