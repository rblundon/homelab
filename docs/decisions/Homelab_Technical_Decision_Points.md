# Homelab Technical Decision Points

## Network Hardware: 

- Ubiquiti

+ ## Networks

   + Default

      **VAN:** 1

      **Subnet:** 192\.168.1.0/24

      **WiFi:** None

      Firewall Rules:

   + Main

      **VAN:** 10

      **Subnet:** 192\.168.10.0/24

      **WiFi:** TheInternet

      Firewall Rules:

   + Guest

      **VAN:** 3

      **Subnet:** 192\.168.3.0/24

      **WiFi:** BeOurGuest

      **Firewall Rules:**

   + Servers Trusted

      **VAN:** 71

      **Subnet:** 10\.1.71.0/24

      **WiFi:** ImaginationInstitute

      Firewall Rules:

   + Servers Untrusted

      **VAN:** 82

      **Subnet:** 10\.1.82.0/24

      **WiFi:** None

      Firewall Rules:

   + IoT

      **VAN:** 2

      **Subnet:** 192\.168.2.0/24

      **WiFi:** IoT

      Firewall Rules:

   + Cameras

      **VAN:** 9

      **Subnet:** 192\.168.9.0/24

      **WiFi:** Cameras

      Firewall Rules:

## NAS: 

- Synology (`emporium`)

## SAN:

- Pure Storage FlashArray (`utilidor`)

+ ## Server Hardware:

   - Minisforum MS-01 (3)

   - Minisforum H60 (3) (Overflow)

   Hypervisors:

   - Proxmox (3)

   Operating Systems

   - Linux:

      - Fedora

      - Ubuntu (Preferred)

   PXE

   - Matchbox

   Automation:

   - Ansible CLI

   - AAP

   - Terraform

   ### Need to make decisions on what to host on:

   - LXC

   - VMs

   - Kubernetes

   - Docker

   - Podman

## Primary Infrastructure Server

***infra01*** *(Deprecated — services have been distributed to dedicated hosts)*

Services previously hosted here have been migrated:

- Authoritative DNS → `monorail` (Technitium LXC)
- Identity Management → `turnstile` (Authentik VM)
- Automation (Ansible) → `imagineering` (Semaphore VM)
- Infrastructure as Code (Terraform) → `city-hall` (VM)
- iPXE (Matchbox) → TBD







### **1\.0 Executive Summary**

This document outlines the technical decisions regarding the IP address allocation and thematic naming conventions for the `mk-labs` homelab environment. The chosen theme is **Magic Kingdom at Walt Disney World**, providing a cohesive and scalable framework for all physical and virtual assets. This approach enhances organization and simplifies management. The domain for all local services will be `[local.mk-labs.cloud](local.mk-labs.cloud)`.

### **2\.0 Networks**

This section details the VLANs configured for the homelab environment.

| Network Name | VLAN ID | Gateway | Subnet | DNS Server | DHCP Range | 
|---|---|---|---|---|---|
| **Default** | 1 | `192.168.1.1` | `192.168.1.0/24` | Server | `192.168.1.110 - .254` | 
| **Guest** | 3 | `192.168.3.1` | `192.168.3.0/24` | Server | `192.168.3.6 - .254` | 
| **Server Trusted** | 71 | `10.1.71.1` | `10.1.71.0/24` | Server | `10.1.71.210 - .230` | 
| **IoT** | 2 | `192.168.2.1` | `192.168.2.0/24` | Server | `192.168.2.6 - .254` | 
| **Management** | 21 | `10.10.21.1` | `10.10.21.0/24` | Server | `10.10.21.200 - .254` | 
| **Server Untrusted** | 250 | `192.168.250.1` | `192.168.250.0/24` | None | \- | 
| **Storage** | 121 | `10.10.121.1` | `10.10.121.0/24` | Server | `10.10.121.6 - .254` | 
| **Cluster** | 22 | `10.10.22.1` | `10.10.22.0/24` | None | \- | 
| **Main** | 10 | `192.168.10.1` | `192.168.10.0/24` | Server | `192.168.10.6 - .254` | 
| **Cameras** | 9 | `192.168.9.1` | `192.168.9.0/24` | Server | `192.168.9.6 - .254` | 

### **2\.1 Server VLAN IP Allocation Strategy**

IP addresses within the **Server Trusted** VLAN (`10.1.71.0/24`) will be statically assigned in CIDR-aligned blocks to ensure predictability and simplify firewall rule management.

| CIDR Block | Usable Range | Purpose | Management | 
|---|---|---|---|
| **`10.1.71.0/27`** | `.1 - .30` | Core Infrastructure (Proxmox Hosts, Storage, Networking) | Static IP | 
| **`10.1.71.32/27`** | `.33 - .62` | Critical Network Services (DNS, NTP, IDM, Automation) | Static IP | 
| **`10.1.71.64/26`** | `.65 - .126` | Container Orchestration (Kubernetes Nodes & VIPs) | Static IP | 
| **`10.1.71.128/25`** | `.129 - .254` | General Applications & VM Pool | Static IP or DHCP Reservation | 

### **3\.0 DNS Architecture**

The DNS strategy is split between external and internal resolution.

- **Recursive DNS (External Resolution):** Handled by the UDM Pro (`world-drive`) using DNS over HTTPS (DoH) with Cloudflare Zero Trust. No self-hosted recursive servers will be deployed.

- **Authoritative DNS (Internal Resolution):** The `monorail` host, a Technitium DNS LXC, is the sole authoritative source for all queries for the internal `[local.mk-labs.cloud](local.mk-labs.cloud)` domain.

- **DNS Forwarding:** A DNS forwarding record on `world-drive` directs all queries for `[local.mk-labs.cloud](local.mk-labs.cloud)` to the `monorail` host, enabling seamless internal name resolution.

### **3\.2 Master Hostname & IP Allocation**

This table serves as the single source of truth for all statically assigned hostnames and IP addresses within the server VLAN (`10.1.71.0/24`).

#### Core Infrastructure (`10.1.71.0/27`)

| Hostname | IP Address | Role / Service | Application | Hardware | Notes | 
|---|---|---|---|---|---|
| `world-drive` | `10.1.71.1` | Router | Unifi 9.x | UDM Pro | Physical | 
| `utilidor` | `10.1.71.5` | SAN | Pure Storage FlashArray | FlashArray | Physical | 
| `utilidor-ct0` | `10.1.71.6` | SAN Controller | Pure Storage FlashArray | FlashArray | Physical | 
| `utilidor-ct1` | `10.1.71.7` | SAN Controller | Pure Storage FlashArray | FlashArray | Physical | 
| `emporium` | `10.1.71.9` | Network Attached Storage | Synology DSM | Synology 1621+ | Physical | 
| `main-street-usa` | `10.1.71.11` | Virtualization Server | Proxmox 9.x | Minisforum TH-60 | Physical | 
| `tomorrowland` | `10.1.71.12` | Virtualization Server | Proxmox 9.x | Minisforum TH-60 | Physical | 
| `fantasyland` | `10.1.71.13` | Virtualization Server | Proxmox 9.x | Minisforum TH-60 | Physical | 

#### Critical Network Services (`10.1.71.32/27`)

| Hostname | IP Address | Role / Service | Application | Hardware | Notes | 
|---|---|---|---|---|---|
| `monorail` | `10.1.71.32` | Authoritative DNS | Technitium | — | LXC | 
| `sundial` | `10.1.71.33` | Local Time Server | Chrony | — | LXC | 
| `fire-station` | `10.1.71.34` | IPAM / Source of Truth | NetBox | — | LXC | 
| `lightning-lane` | `10.1.71.35` | Reverse Proxy / Load Balancer | Traefik | — | VM (Docker Compose / Boilerplates) | 
| `tiki-room` | `10.1.71.36` | Workflow Orchestration | n8n | — | VM (Docker Compose) | 
| `imagineering` | `10.1.71.37` | Automation Server (Ansible) | Semaphore | — | VM | 
| `city-hall` | `10.1.71.38` | Infrastructure as Code | Terraform / Boilerplates CLI | — | VM | 
| `timekeeper` | `10.1.71.39` | Backup & Recovery | Proxmox Backup Server | — | VM | 
| `turnstile` | `10.1.71.40` | Identity Provider / SSO | Authentik | — | VM (Docker Compose / Boilerplates) | 
| `cinderella-castle` | `10.1.71.41` | Monitoring & Observability | Prometheus / Grafana | — | VM | 

#### Container Orchestration (`10.1.71.64/26`)

| Hostname | IP Address | Role / Service | Application | Hardware | Notes | 
|---|---|---|---|---|---|
| `space-mountain` | `10.1.71.65` | K8s Control Plane | TalosOS | — | VM | 
| `big-thunder-mountain` | `10.1.71.66` | K8s Control Plane | TalosOS | — | VM | 
| `splash-mountain` | `10.1.71.67` | K8s Control Plane | TalosOS | — | VM | 
| `jungle-cruise` | `10.1.71.68` | K8s Worker (on-stage) | TalosOS | — | VM | 
| `haunted-mansion` | `10.1.71.69` | K8s Worker (backstage) | TalosOS | — | VM | 
| `peter-pans-flight` | `10.1.71.70` | K8s Worker (backstage) | TalosOS | — | VM | 

#### General Applications & VM Pool (`10.1.71.128/25`)

| Hostname | IP Address | Role / Service | Application | Hardware | Notes | 
|---|---|---|---|---|---|
| `be-our-guest` | `10.1.71.129` | Web Server | WordPress | — | K8s (on-stage) | 
| `main-street-station` | `10.1.71.130` | Application Dashboard | TBD | — | K8s (backstage) | 
| `arcade` | `10.1.71.131` | Game Server | Minecraft | — | K8s (backstage) | 
| `people-mover` | `10.1.71.132` | Project Management | Plane.so | — | K8s (backstage) | 

*(This table will be populated as new services are deployed)*

### **3\.3 Naming Standards**

### **3\.3.1 Physical Infrastructure**

The core physical hardware will be named after the foundational "lands" and infrastructure of the Magic Kingdom.

| Role | Name | Description | 
|---|---|---|
| **Proxmox Cluster** | `magic-kingdom` | The name for the entire Proxmox cluster, representing the whole park. | 
| **Primary Proxmox Host** | `main-street-usa` | The foundational "land" and entry point, hosting critical services. | 
| **Expansion Hosts** | `tomorrowland`, `fantasyland`, etc. | Additional hosts named after the other lands of the park. | 
| **NAS (Synology)** | `emporium` | The Main Street shop where everything is available, representing the central NAS. | 
| **SAN (Pure Storage)** | `utilidor` | The backstage service tunnels, representing the enterprise block storage system. | 

### **3\.3.2 Service & Application Naming**

| Service Category | Name | Thematic Reason | 
|---|---|---|
| **Authoritative DNS** | `monorail` | The primary, official transportation system, authoritative for all park routes. | 
| **Automation Server** | `imagineering` | The engineering division that designs and builds everything in the park. | 
| **Identity Provider / SSO** | `turnstile` | The authentication gate — you can't enter the Magic Kingdom without passing through it. | 
| **Reverse Proxy / Load Balancer** | `lightning-lane` | The fast-track system that routes guests efficiently to their destination. | 
| **Workflow Orchestration** | `tiki-room` | The enchanted show where everything is automated and orchestrated in harmony. | 
| **Infrastructure as Code** | `city-hall` | The administrative headquarters where all park operations are planned and managed. | 
| **IPAM / Source of Truth** | `fire-station` | The first building on Main Street, the foundational source of truth for the park. | 
| **Monitoring Dashboard** | `cinderella-castle` | The central viewpoint with a line of sight to the entire homelab. | 
| **Application Dashboard** | `main-street-station` | The central station and starting point to access all applications. | 
| **Backup & Recovery** | `timekeeper` | The time-traveling attraction, protecting and preserving data across time. | 
| **Security Services (IDS/IPS)** | `space-rangers` | An elite force protecting the network from threats. | 
| **Password Manager** | `pirates-of-the-caribbean` | The attraction dedicated to protecting valuable treasure (passwords). | 
| **CI/CD Platform** | `tron-lightcycle-run` | The futuristic attraction where applications are built on "the Grid." | 

### **4\.0 Storage Architecture**

Storage for the `magic-kingdom` Proxmox cluster is provided by two systems:

- **`emporium`** (Synology 1621+): General-purpose NAS providing NFS & iSCSI storage for VMs, LXCs, and ISOs.
- **`utilidor`** (Pure Storage FlashArray): Enterprise block storage for high-performance workloads and Kubernetes persistent volumes (via democratic-csi).

The following LUNs have been created on `emporium` and assigned to the cluster for shared storage.

| LUN Name | Size | Purpose | 
|---|---|---|
| `mk-general` | 2T | General purpose storage for VMs, LXCs, and ISOs. | 
| `mk-templates` | 1T | Dedicated storage for VM and LXC templates. | 

### **5\.0 Core Services Hosting Strategy**

Core services are deployed using a tiered model based on their relationship to the Kubernetes cluster (`fastpass`):

**Tier 1 — Outside Kubernetes (Proxmox LXC/VM):**
Services that Kubernetes depends on to function, or that must exist before the cluster can bootstrap. These are provisioned via Terraform + Ansible through the IaC pipeline on `city-hall`.

- **LXC deployments:** Lightweight services with no full kernel requirements (DNS, NTP, IPAM).
- **VM deployments (Docker Compose via Boilerplates):** Services requiring a full OS, Docker runtime, or operational flexibility (automation, orchestration, identity, ingress). Docker Compose templates are generated using the [Christian Lempa Boilerplates CLI](https://github.com/ChristianLempa/boilerplates) installed on `city-hall`.

**Tier 2 — Inside Kubernetes (ArgoCD/Helm):**
Application workloads with no circular dependency on the cluster. Managed declaratively via ArgoCD and Helm charts, deployed into `on-stage` or `backstage` zones.

**Retired approach:** Proxmox VE Community Helper Scripts are no longer used for production deployments in favor of fully codified IaC.

### **6\.0 Kubernetes Architecture**

The primary Kubernetes cluster will be named `fastpass`. The name is derived from the park's system for orchestrating access to resources, which is a direct metaphor for Kubernetes' function.

#### **6\.1 Deployment Technology Stack**

- **Operating System: `TalosOS`**

   - **Reasoning:** TalosOS is a purpose-built, immutable Linux distribution for Kubernetes. Nodes are API-managed via `talosctl` with no SSH access, reducing attack surface and configuration drift. Machine configs define the entire node state declaratively.

- **Deployment Pipeline:**

   - NetBox (`fire-station`) → n8n (`tiki-room`) → Terraform (`city-hall`, using Proxmox + Talos providers) → `talosctl bootstrap` → ArgoCD takes over

   - **Note:** Ansible (`imagineering`) does **not** touch Talos nodes. It is scoped exclusively to Tier 1 LXC/VM infrastructure.

#### **6\.2 Deployment Model**

A single-cluster model will be used for resource efficiency and to reduce management overhead. Workload isolation between internal and external-facing applications will be achieved using logical "zones" within the cluster, enforced by Kubernetes-native tools.

- **Worker Node Zones:** Worker nodes will be separated into two thematic zones based on Disney park operational terms:

   - **`on-stage`:** This zone is for external-facing services (the "DMZ"). It represents the public areas of the park. Nodes in this zone will be tainted to prevent untrusted workloads from being scheduled on them.

   - **`backstage`:** This zone is for internal-only services. It represents the secure, operational core of the park.

- **Workload Placement:** Pod scheduling will be controlled via **labels**, **`nodeAffinity`**, and **tolerations**.

- **Network Security:** Traffic flow between zones and pods will be strictly controlled using **Network Policies**.

#### **6\.3 Node Naming Convention**

- **Control Plane Nodes:** Named after the iconic "Mountain" attractions. These are the largest, most complex, and critical rides that form the backbone of the park.

- **Worker Nodes:** Named after other classic "E-Ticket" attractions. These are the high-capacity workhorses that run the majority of the park's experiences.

| Role | Initial Node Names | Zone | 
|---|---|---|
| **Control Plane** | `space-mountain`, `big-thunder-mountain`, `splash-mountain` | N/A | 
| **Worker Node 1** | `jungle-cruise` | `on-stage` | 
| **Worker Node 2** | `haunted-mansion` | `backstage` | 
| **Worker Node 3** | `peter-pans-flight` | `backstage` | 

### **7\.0 Decision Summary**

The adoption of this comprehensive thematic naming convention provides a logical, scalable, and engaging framework for the `mk-labs` homelab. It ensures that every component has a clear and memorable identity that aligns with its function.

### **Appendix A: Additional Hostname Ideas**

This section contains a list of pre-approved hostname ideas for future services.

| Service Category | Recommended Name | Thematic Reason | 
|---|---|---|
| **VPN Server** | `magical-express` | Securely transports you from the outside world into the private network. | 
| **Ad Blocker** | `orange-bird` | A friendly service that works silently to make the user experience better. | 
| **Code Server / Dev Env** | `mickeys-toontown-fair` | A creative, hands-on place for building and experimenting with code. | 
| **Home Automation** | `carousel-of-progress` | The attraction that showcases the evolution of technology in the home. | 
| **Game Server** | `tom-sawyer-island` | An island dedicated to adventure, exploration, and play. | 
| **Recipe Manager** | `caseys-corner` | The iconic hot dog spot; a simple name for a service that manages food. | 

### **Appendix B: Assigned Hostnames (Previously in Appendix A)**

These hostnames have been assigned to active services and are documented here for reference.

| Service Category | Assigned Name | Assigned To | 
|---|---|---|
| **NAS** | `emporium` | Synology 1621+ (`10.1.71.9`) | 
| **Identity Provider / SSO** | `turnstile` | Authentik (`10.1.71.40`) | 

