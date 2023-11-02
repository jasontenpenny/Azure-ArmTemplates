# VNet with Azure Firewall

This template is used to create a simple VNet with 3 subnets: jumpbox-subnet, app-subnet, and db-subnet.

In order to faciliate outbound connection from ACSS VMs once deployed, this template also includes the deployment of an Azure Firewall that protects app-subnet and db-subnet. The firewall has some basic rules on it that allow outbound internet traffic. The jumpbox-subnet is not protected by the firewall, as it is simpler to manage access to a jumpbox VM with just the NSG rules.

# Disclaimer

This template and associated scripts is **not** suited for use in a production environment! The goal of this deployment template is to speed up the process of building a test environment for learning more about SAP Hana. The template and scripts are provided as is with no warranty for issues.