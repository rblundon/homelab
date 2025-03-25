# Configure the DNS Provider
provider "freeipa" {
  host        = "infra01.int.mk-labs.cloud"
  username    = "admin"
  password    = var.freeipa_password
  insecure    = true
}

variable "freeipa_password" {
  description = "The password for the FreeIPA provider"
  type        = string
  sensitive   = true
}

terraform {
  required_providers {
    freeipa = {
      source = "rework-space-com/freeipa"
      version = "5.0.0"
    }
  }
}
