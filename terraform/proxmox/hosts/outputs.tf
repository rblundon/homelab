# ─── Outputs ─────────────────────────────────────────────────────────────────

output "vm_id" {
  description = "Proxmox VM ID"
  value       = module.vm.vm_id
}

output "hostname" {
  description = "VM hostname"
  value       = var.hostname
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}

output "target_node" {
  description = "Proxmox node the VM is placed on"
  value       = var.target_node
}
