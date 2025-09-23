##################################################################################
# LOCALS
##################################################################################

# Reminder to disable the firewall before starting (or allow port 8543)
# sudo systemctl stop firewalld

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
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

##################################################################################
# SOURCE
##################################################################################

source "proxmox-iso" "ubuntu-2404" {
  boot_iso {
    type = "scsi"
    iso_file = "${var.proxmox_iso_storage_pool}:iso/${var.iso_file}"
    unmount = true
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

  # VM Cloud-Init Settings
  cloud_init = true
  cloud_init_storage_pool = "${var.proxmox_vm_storage_pool}"

  boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
  ]
  boot = "c"
  boot_wait = "5s"

  # PACKER Autoinstall Settings
  http_directory = "./http" 
    
  # (Optional) Bind IP Address and Port
  # http_bind_address = "10.1.149.166"
  http_port_min = 8543
  http_port_max = 8543

  sockets         = "${var.vm_cpu_sockets}"
  cores           = "${var.vm_cpu_cores}"
  cpu_type        = "host"
  # machine         = "q35"
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
  ssh_private_key_file = "${var.ssh_private_key}"
  template_description = "Ubuntu 24.04.3, generated on ${timestamp()}"
  template_name        = "${var.vm_name}"
}

##################################################################################
# BUILD
##################################################################################
#    inline          = ["dnf -y update", "dnf -y install python-pip", "python3 -m pip install --upgrade pip", "alternatives --set python /usr/bin/python3", "pip3 install ansible"]

build {
  sources = ["source.proxmox-iso.ubuntu-2404"]
  # name = "ubuntu-24.04.3"

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
      inline = [
          "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
          "sudo rm /etc/ssh/ssh_host_*",
          "sudo truncate -s 0 /etc/machine-id",
          "sudo apt -y autoremove --purge",
          "sudo apt -y clean",
          "sudo apt -y autoclean",
          "sudo cloud-init clean",
          "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
          "sudo rm -f /etc/netplan/00-installer-config.yaml",
          "sudo sync"       
      ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
      source = "files/99-pve.cfg"
      destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
      inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }
}
