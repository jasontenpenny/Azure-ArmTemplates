# VNet with NAT Gateway

This template is used to create a simple VNet with 3 subnets: jumpbox-subnet, app-subnet, and db-subnet.

In order to faciliate outbound connection from ACSS VMs once deployed, this template also includes the deployment of an Azure NAT Gateway that protects app-subnet and db-subnet. The jumpbox-subnet is not behind the NAT GW, as it is designed to house a VM with a public IP, so the NAT GW is not needed.

# Deploy Template

Use the following button to deploy the template.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjasontenpenny%2FAzure-ArmTemplates%2Fmain%2FSAP%2FACSS-prereqs%2FVNet-with-NatGW%2FVNet-with-NatGW.json)

# Disclaimer

This template and associated scripts is **not** suited for use in a production environment! The goal of this deployment template is to speed up the process of building a test environment for learning more about SAP Hana. The template and scripts are provided as is with no warranty for issues.