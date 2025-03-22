// Matcher group for OCP Internal machinesmachines
resource "matchbox_group" "ocp-hub" {
  name = "ocp-hub" # Physical Server
  profile = matchbox_profile.hub.name
  selector = {
    mac = "98:b7:85:1e:c6:f1" # PXE boots and installs to 10GbE NIC
  }
}
