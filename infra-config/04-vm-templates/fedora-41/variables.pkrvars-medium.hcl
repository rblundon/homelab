##################################################################################
# VARIABLES
##################################################################################

# HTTP Settings

http_directory = "http"

# Virtual Machine Settings

vm_name                     = "centos9-medium"
vm_guest_os_type            = "centos8_64Guest"
vm_version                  = 19
vm_firmware                 = "efi"
vm_cdrom_type               = "sata"
vm_cpu_sockets              = 1
vm_cpu_cores                = 1
vm_mem_size                 = 2048
vm_disk_size                = 25600
thin_provision              = true
disk_eagerly_scrub          = false
vm_disk_controller_type     = ["pvscsi"]
vm_network_card             = "vmxnet3"
vm_boot_wait                = "5s"
ssh_username                = "wed"
ssh_password                = "1mag!ne3R"

# ISO Objects

iso_checksum                = "ca03867ab88fbe565b91ae518e6f7f83debe6415234f29ff2cc5634052840ce8"
iso_checksum_type           = "sha256"
iso_url                     = "https://mirror.rackspace.com/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"
# Scripts

shell_scripts               = ["scripts/cleanup.sh"]
