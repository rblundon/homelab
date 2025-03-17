# A Homelab based on Red Hat Technologies

This repository is the configuration of my homelab. In addition to providing services, the purpose of my homelab is to learn advanced concepts primarily based on Red Hat OpenShift.

This implementation is built on easily accessible consumer based hardware and will focus heavily on GitOps practices and automation will be used wherever possible.

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

- DNS
- Domain Registration

## Assumptions

There are a dozen different architectures you could use to deploy OpenShift in every which way.
For the sake of this documentation we'll assume the following:

## Getting Started

### Hub Cluster

You'll need an OpenShift "Hub Cluster" with access to persistant storage.
A Single Node OpenShift (SNO) instance, installed on bare metal, will act as a Hub cluster and run:

- Advanced Cluster Management
- Ansible Automation Platform
- Vault
- OpenShift GitOps

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

With everything in its right place, you can now start to declaratively create clusters - so choose your own adventure:

./05-clusters/hcp-bmh - HCP to Bare Metal Hosts

### Internal Cluster

Two additional bare metal nodes, to be added to Advanced Cluster Management (ACM) running on the SNO Hub. These will be used to create another two HCP clusters.
These servers have a BMC interface with Redfish - if not, then you'll need to manually manage the boot and installation of those servers.
This makes it to where you just need 3 bare metal nodes. You could run one HCP Bare Metal cluster with both of the other nodes, but then you have a shared storage requirement that can't be satisfied by ODF since that needs at least 3 nodes.

### External Cluster

You'll also either need you just need at least 2 bare metal nodes.

Credit to Ken Moini as I used his [repo](https://github.com/kenmoini/ztp-for-you-and-me) as the baseline for this project.
