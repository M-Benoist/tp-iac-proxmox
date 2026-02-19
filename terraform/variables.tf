variable "proxmox_api_url" { type = string }
variable "proxmox_api_token" { type = string }
variable "target_node" { type = string }
variable "template_id" { type = number }
variable "web_ip" { type = string }
variable "db_ip"  { type = string }
variable "gateway" { type = string }
variable "web_vm_id" { type = number }
variable "db_vm_id"  { type = number }
variable "env" {
	 type = string
	 description = "Nom de l'environnement (prod ou staging)"
}
