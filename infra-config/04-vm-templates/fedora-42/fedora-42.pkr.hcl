##################################################################################
# LOCALS
##################################################################################

locals {
  buildtime = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

packer {
  required_plugins {
    ansible = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/ansible"
    }
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

##################################################################################
# SOURCE
##################################################################################

source "proxmox-iso" "fedora-kickstart" {
  #insecure_skip_tls_verify = "${var.proxmox_insecure_verify}"

  boot_iso {
    type = "scsi"
    iso_file = "${var.proxmox_iso_storage_pool}:iso/${var.iso_file}"
    unmount = true
      #iso_checksum = "sha512:33c08e56c83d13007e4a5511b9bf2c4926c4aa12fd5dd56d493c0653aecbab380988c5bf1671dbaea75c582827797d98c4a611f7fb2b131fbde2c677d5258ec9"
    iso_checksum = "${var.iso_checksum_type}:${var.iso_checksum}"
  }

  os   = "l26"
  bios = "ovmf"
  vm_id = "${var.vm_id}"

  efi_config {
    efi_storage_pool  = "${var.proxmox_vm_storage_pool}"
    efi_type          = "4m"
    #pre_enrolled_keys = true
  }

  http_directory      = "http"

  boot_command = [
    "<up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg <f10>"
  ]

  boot_wait    = "${var.vm_boot_wait}"

  sockets         = "${var.vm_cpu_sockets}"
  cores           = "${var.vm_cpu_cores}"
  cpu_type        = "host"
  memory          = "${var.vm_mem_size}"
  scsi_controller = "virtio-scsi-single"

  disks {
    storage_pool      = "${var.proxmox_vm_storage_pool}"
    disk_size         = "${var.vm_disk_size}G"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "${var.proxmox_bridge}"
#    vlan_tag = "${var.proxmox_vlan}"
    firewall = "true"
  }

  node                 = "${var.proxmox_node}"
  username             = "${var.proxmox_username}"
  password             = "${var.proxmox_password}"
  proxmox_url          = "https://${var.proxmox_node}.${var.proxmox_domain}:8006/api2/json"
  ssh_timeout          = "15m"
  ssh_username         = "${var.ssh_username}"
  ssh_password         = "${var.ssh_password}"
  template_description = "Fedora 41-1.4, generated on ${timestamp()}"
  template_name        = "${var.vm_name}"
}

##################################################################################
# BUILD
##################################################################################
#    inline          = ["dnf -y update", "dnf -y install python-pip", "python3 -m pip install --upgrade pip", "alternatives --set python /usr/bin/python3", "pip3 install ansible"]

build {
  sources = ["source.proxmox-iso.fedora-kickstart"]
  #name    = "${var.vm_mame}"
  provisioner "shell" {
    execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = [
      "dnf -y update",
      "dnf -y install python-pip",
      "pip install ansible"
    ]
  }

  provisioner "file" {
    source = "files/ansible.pub"
    destination = "/tmp/ansible.pub"
  }

  provisioner "shell" {
    execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = [
      "mkdir /home/wed/.ssh",
      "chown wed:wed /home/wed/.ssh",
      "cat /tmp/ansible.pub > /home/wed/.ssh/authorized_keys",
      "chmod 600 /home/wed/.ssh/authorized_keys",
      "chown wed:wed /home/wed/.ssh/authorized_keys",
      "rm /tmp/ansible.pub"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "scripts/setup.yml"
  }

  provisioner "shell" {
    execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = [
      "scripts/cleanup.sh"
    ]
  }
 }
