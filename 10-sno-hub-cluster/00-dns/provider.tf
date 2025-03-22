# Configure the DNS Provider
provider "freeipa" {
  host        = "infra01.int.mk-labs.cloud"
  username    = "admin"
  password    = "Gen1:1NASB"
  insecure    = true
}

terraform {
  required_providers {
    freeipa = {
      source = "rework-space-com/freeipa"
      version = "5.0.0"
    }
  }
}
