# A Homelab based on Red Hat Technologies

A comprehensive homelab for learning advanced concepts primarily based on Red Hat OpenShift.  In addition to providing services, it is an area to incorporate container technologies, and enterprise integration scenarios.

This implementation is built on easily accessible consumer based hardware and will focus heavily on GitOps practices and automation will be used wherever possible.

## 🎯 Project Goals

- **Multi-cluster OpenShift management** with ACM
- **Hybrid cloud scenarios** (bare metal + virtualized + containerized)
- **Enterprise integration testing** (AD, SQL Server, SIEM)
- **GitOps and automation workflows**
- **Red Hat certification preparation**

## 📋 Documentation (Priority Order)

### Phase 1: Foundation
1. **[Overview & Hardware Allocation](./docs/01-overview.md)** - Complete architecture overview
2. **[Networking Plan](./docs/02-networking.md)** - VLAN strategy and network design
3. **[Core Services Setup](./docs/03-core-services.md)** *(TBD)* - k0s cluster, DNS, monitoring
4. **[Storage Configuration](./docs/04-storage.md)** *(TBD)* - Synology, democratic-csi

### Phase 2: Container Platform
5. **[Container Registry Setup](./docs/05-container-registry.md)** *(TBD)* - Harbor deployment
6. **[Git Repository Setup](./docs/06-git-repository.md)** *(TBD)* - Gitea/GitLab on Synology
7. **[Artifact Repository](./docs/07-artifact-repository.md)** *(TBD)* - Nexus/Artifactory

### Phase 3: OpenShift Clusters
8. **[OpenShift Compact Cluster](./docs/08-openshift-compact.md)** *(TBD)* - 3-node production-like
9. **[OpenShift SNO + Worker](./docs/09-openshift-sno.md)** *(TBD)* - Edge computing setup
10. **[ACM Configuration](./docs/10-acm-setup.md)** *(TBD)* - Multi-cluster management

### Phase 4: vSphere Platform
11. **[vSphere Installation](./docs/11-vsphere-setup.md)** *(TBD)* - Dell T640 virtualization
12. **[Windows Infrastructure](./docs/12-windows-infrastructure.md)** *(TBD)* - AD, SQL Server
13. **[VM Templates & Automation](./docs/13-vm-automation.md)** *(TBD)* - Template creation

### Phase 5: Advanced Services
14. **[Monitoring & Observability](./docs/14-monitoring.md)** *(TBD)* - Prometheus, Grafana, Splunk
15. **[Security & Compliance](./docs/15-security.md)** *(TBD)* - ACS, certificates, auditing
16. **[Backup & DR](./docs/16-backup-dr.md)** *(TBD)* - Backup strategies

## 🚀 Quick Start Deployment

### Prerequisites
- Ubiquiti UDM SE configured
- Hardware powered and networked
- Initial VLAN setup (see [networking plan](./docs/02-networking.md))

Ansible Collections
- ansible-galaxy collection install freeipa.ansible_freeipa

### Deployment Scripts

```bash
source ~/venv-ansible/bin/activate
# Phase 1: Foundation
./scripts/01-network-setup.sh
./scripts/02-core-services-deploy.sh

# Phase 2: Container Platform  
./deployment/synology/docker-compose.yml  # Git repo, Harbor, Nexus
./scripts/03-storage-setup.sh

# Phase 3: OpenShift
./deployment/openshift/compact-cluster/
./deployment/openshift/sno-cluster/

# Phase 4: vSphere
./deployment/vsphere/
```

## 📁 Repository Structure

```
homelab-plan/
├── README.md                    # This file
├── docs/                        # Documentation (numbered by priority)
│   ├── 01-overview.md
│   ├── 02-networking.md
│   └── ...
├── deployment/                  # Deployment configurations
│   ├── synology/               # Docker Compose files for Synology
│   ├── k0s/                    # k0s cluster manifests
│   ├── openshift/              # OpenShift installation configs
│   └── vsphere/                # vSphere automation
├── scripts/                     # Automation scripts
└── .gitignore                   # Excludes sensitive data
```

## 🔧 Technology Stack

### Infrastructure
- **Networking**: Ubiquiti UDM SE
- **Storage**: Synology DS1621+, Ubiquiti UNAS Pro
- **Compute**: 3x Beelink S12 Pro, 5x Lenovo M710q, Dell T640

### Container Platforms
- **OpenShift 4.14+**: Two clusters (compact + SNO)
- **k0s**: Core services cluster
- **vSphere**: VM workloads

### Core Services
- **Container Registry**: Harbor
- **Git Repository**: Gitea/GitLab CE
- **Artifact Repository**: Nexus/Artifactory
- **Monitoring**: Prometheus + Grafana
- **Logging**: Splunk Enterprise
- **DNS**: CoreDNS
- **Load Balancing**: MetalLB + HAProxy

## 🔐 Security Notes

- **No sensitive data** is stored in this repository
- **Secrets management** via external-secrets-operator
- **Certificate management** via cert-manager
- **Network segmentation** via VLANs and firewall rules

## 🤝 Contributing

This is a personal homelab project, but feel free to:
- Submit issues for questions or suggestions
- Fork for your own homelab adaptations
- Share improvements via pull requests

## 📞 Next Steps

1. **Create GitHub repository** for version control
2. **Start with Phase 1** foundation setup
3. **Build deployment automation** as we go
4. **Document lessons learned** for future reference

---

**Status**: 🚧 Planning & Initial Development

**Last Updated**: June 2025

This repo is a mono-repo that is broken up into three sections:

- infra-config
- apps
- cluster

## Hardware

- Dell 7050 SFF (7)
- Minisforum TH60 (3)
- Minisforum MS01 (2)
- Synology 1621+

## Software

- Proxmox (Virtualization)
- Cloudflare (Domain Hosting, Public DNS)
- Unbound (Recursive DNS)
- FreeIPA (Identity management, Authoritive DNS)
- Matchbox (iPXE)
- Red Hat OpenShift
- OpenShift Agent Based Installer (Install OpenShift)
  - [Red Hat Advanced Cluster Management for Kubernetes](https://www.redhat.com/en/technologies/management/advanced-cluster-management)
  - [Vault](https://www.hashicorp.com/en/products/vault)
  - [OpenShift GitOps (ArgoCD)](https://www.redhat.com/en/technologies/cloud-computing/openshift/gitops)
  - [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)

## Prerequisites

- Ansible user created
- Ansible configured
- [Networking](docs/networks.md)
- [Proxmox](docs/proxmox.md) (In my homelab, internal DNS, identity manangement, and ipxe are hosted here.)
- Matchbox
- DNS
- Domain Registration

## Assumptions

There are a dozen different architectures you could use to deploy OpenShift in every which way.
For the sake of this documentation we'll assume the following:

## Getting Started

[Step-by-Step Walkthrough](step-by-step.md)

### Hub Cluster

You'll need an OpenShift "Hub Cluster" with access to persistant storage.
A Single Node OpenShift (SNO) instance, installed on bare metal, will act as a Hub cluster and run:

- Advanced Cluster Management
- Ansible Automation Platform
- Vault
- ~~OpenShift GitOps~~

#### Network Prerequisites

The prerequisites for OpenShift in traditional and HCP patterns are largely the same - it just kind of depends on where your DNS records go to.

| Cluster           | Endpoint    | VIP           | DNS A Record                      | Notes                           |
|------------------|-------------|---------------|-----------------------------------|----------------------------------|
| Hub Cluster (SNO) | App Ingress | 192.168.0.10 | *.apps.hub-cluster.example.com    | SNO App VIP goes to IP of node  |
| Hub Cluster (SNO) | API         | 192.168.0.10 | api.hub-cluster.example.com       | SNO API goes to IP of node      |

These DNS entries should be put in your Authoratitive DNS.

#### ACM & GitOps Configuration

Before you start creating clusters you may want to create some Policies, integrate ACM and ArgoCD, etc. This step is optional in case you're just interested in trying out Hosted Control Planes or copy/paste around a cluster for testing purposes.

Find additional details in the ./02-rhacm-config folder.

#### Creating a Cluster

With everything in its right place, you can now start to declaratively create clusters

./05-clusters/hcp-bmh - HCP to Bare Metal Hosts

### Internal Cluster

Two additional bare metal nodes, to be added to Advanced Cluster Management (ACM) running on the SNO Hub. These will be used to create another HCP cluster.
These servers have a BMC interface with Redfish - if not, then you'll need to manually manage the boot and installation of those servers.
This makes it to where you just need 3 bare metal nodes. You could run one HCP Bare Metal cluster with both of the other nodes, but then you have a shared storage requirement that can't be satisfied by ODF since that needs at least 3 nodes.

### External Cluster

You'll also either need you just need at least 2 bare metal nodes.

---

## Credits

- Ken Moini - As I used his [repo](https://github.com/kenmoini/ztp-for-you-and-me) as the baseline for this project.
- Ryan Etten
- Andrew Potozniak
