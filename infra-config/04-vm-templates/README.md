# Steps for creating VM templates with Hashicorp Packer

As this is one of the early steps, the assumption is made that these commands will be run on a jumpbox/laptop.

Templates will always live on <template-node> within the cluster.

Steps to install Packer:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

packer plugins install github.com/hashicorp/proxmox
packer plugins install github.com/hashicorp/ansible 

my-packer-project/
├── main.pkr.hcl             # Main build definition(s)
├── variables.pkr.hcl        # Variable declarations and default values
├── <image_name>.pkrvars.hcl # (Optional) Specific variable values for a particular image
├── scripts/                 # Directory for shell/PowerShell scripts used by provisioners
│   ├── setup-apache.sh
│   ├── install-deps.ps1
│   └── common-config.sh
├── httpd-template/          # (Optional) Subdirectory for a specific image's configuration
│   ├── source.pkr.hcl       # Source block for Apache image
│   ├── build.pkr.hcl        # Build block for Apache image
│   └── vars.pkrvars.hcl     # Variables specific to Apache image
└── README.md
