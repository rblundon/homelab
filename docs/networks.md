# Networks

My homelab is segmented into a set of networks. Each network is a separate subnet, and each subnet is a separate VLAN that usually corresponds to the 3rd octet of the IPv4 block it aligns to. The following table shows the network and VLAN information:

| Network          | VLAN | DHCP Range         | Description        |
|------------------|------|--------------------|--------------------|
| XXX.XXX.XXX.0/24 |   71 | XXX.XXX.XXX.10-250 | Server network     |
| XXX.XXX.XXX.0/24 |   22 |                    | Cluster network    |
| XXX.XXX.XXX.0/24 |  121 |                    | Storage network    |
