output "vm_id" {
  description = "Proxmox VM ID of the created VM."
  value       = var.vm_id
}

output "mac_address" {
  description = "MAC address of the VM's first network interface."
  value       = proxmox_virtual_environment_vm.vm.network_device[0].mac_address
}

output "hostname" {
  description = "Hostname of the created VM."
  value       = var.hostname
}

output "ip_address" {
  description = "IP address of the created VM."
  value       = var.ip_address
}

output "node_name" {
  description = "Proxmox node where the VM is running."
  value       = proxmox_virtual_environment_vm.vm.node_name
}
