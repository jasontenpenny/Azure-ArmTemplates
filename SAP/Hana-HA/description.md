# SAP Hana HDB HA Environment

Deploys an environment where you can set up an HA cluster between two Hana database VMs.

The minimum deployment is a jumpbox and two Hana database VMs. You can either specify an existing Virtual Network to deploy these in, or you can choose to deploy a new VNet with either a NAT Gateway or an Azure Firewall (to provide internet access).

You can optionally run a script to prepare the data disks for an SAP install.

Additionally, you can optionally trigger an automated installation of SAP Hana. This process assumes that the installation media has previously been downloaded and stored in an Azure Storage account as a blob file. This file must be publically accessible without authentication (anonymous).

## Planned additions

The goal is to further enhance this template so that it will automatically configure the HA settings post install. This component is still under development.