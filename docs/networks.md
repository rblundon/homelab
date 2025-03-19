# Networks

My homelab is segmented into a set of networks. Each network is a separate subnet, and each subnet is a separate VLAN that usually corresponds to the 3rd octet of the IPv4 block it aligns to. The following table shows the network and VLAN information:

| Network         | VLAN | DHCP Range       | Description            |
|-----------------|------|------------------|------------------------|
| 10.1.71.0/24    |   71 | 10.71.1.10-250   | Server network         |
| 10.10.22.0/24   |   22 | Static IPs       | Cluster network        |
| 10.10.121.0/24  |  121 | Static IPs       | Storage network        |
