# VNet with NAT Gateway

This template is used to create a simple VNet with 3 subnets: jumpbox-subnet, app-subnet, and db-subnet.

In order to faciliate outbound connection from ACSS VMs once deployed, this template also includes the deployment of an Azure NAT Gateway that protects app-subnet and db-subnet. The jumpbox-subnet is not behind the NAT GW, as it is designed to house a VM with a public IP, so the NAT GW is not needed.
