// Terraform DNS entry template

resource "freeipa_dns_record" "pve01" {
  zone_name = "int.mk-labs.cloud."
  name = "pve01"
  type = "A"
  records = [
    "10.1.71.51",
  ]
  ttl = 60
}
