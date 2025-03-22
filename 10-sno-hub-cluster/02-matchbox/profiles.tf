// Fedora CoreOS profile
resource "matchbox_profile" "openshift-agent-install" {
  name   = "hub"
  kernel = "/assets/hub/agent.x86_64-vmlinuz"
  initrd = [
    "--name initrd /assets/hub/agent.x86_64-initrd.img"
  ]

  args = [
    "initrd=initrd",
    "coreos.live.rootfs_url=${var.matchbox_http_endpoint}/assets/hub/agent.x86_64-rootfs.img",
    "rw",
    "ignition.firstboot",
    "ignition.platform.id=metal",
  ]
}
