// Terraform DNS entry template

resource "freeipa_dns_record" "ocp-hub" {
  zone_name = "int.mk-labs.cloud."
  name = "ocp-hub"
  type = "A"
  records = [
    "10.1.71.10",
  ]
  ttl = 60
}
