output "reservation_id" {
  description = "Unifi user/client ID for the DHCP reservation."
  value       = unifi_user.vm.id
}
