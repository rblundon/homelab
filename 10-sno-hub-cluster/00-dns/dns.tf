

# resource freeipa_dns_record "bar" {
#   idnsname = "bar"
#   dnszoneidnsname = "myzone"
#   dnsttl = 20
#   records = ["1.2.3.4"]
# }

resource "freeipa_dns_record" "ocp-hub" {
  zone_name = "int.mk-labs.cloud."
  name = "hub"
  type = "A"
  records = [
    "10.1.71.11",
  ]
  ttl = 60
}
resource "freeipa_dns_record" "wildcard-apps" {
  zone_name = "int.mk-labs.cloud."
  name = "*.apps.hub"
  type = "A"
  records = [
    "10.1.71.10",
  ]
  ttl = 60
}
resource "freeipa_dns_record" "api" {
  zone_name = "int.mk-labs.cloud."
  name = "api.hub"
  type = "A"
  records = [
    "10.1.71.10",
  ]
  ttl = 60
}
resource "freeipa_dns_record" "api-int" {
  zone_name = "int.mk-labs.cloud."
  name = "api-int.hub"
  type = "A"
  records = [
    "10.1.71.10",
  ]
  ttl = 60
}
