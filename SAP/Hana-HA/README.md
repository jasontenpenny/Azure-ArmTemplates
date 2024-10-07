# SAP Hana HDB HA Environment

Deploys an environment where you can set up an HA cluster between two Hana database VMs.

The minimum deployment is two Hana database VMs along with their disks and an Azure Load Balancer. You can either specify an existing Virtual Network to deploy these in, or you can choose to deploy a new VNet with either a NAT Gateway or an Azure Firewall (to provide internet access). If you need a jumpbox to connect to these systems, you can elect to deploy that.

You can optionally run a script to prepare the data disks for an SAP install.

Additionally, you can optionally trigger an automated installation of SAP Hana. This process assumes that the installation media has previously been downloaded and stored in an Azure Storage account as a blob file. This file must be publically accessible without authentication (anonymous).

After installing SAP Hana, you can choose to proceed with an automatic configuration of a Hana database cluster, utilizing Pacemaker and Hana System Replication.

# Disclaimer

This template and associated scripts is **not** suited for use in a production environment! The goal of this deployment template is to speed up the process of building a test environment for learning more about SAP Hana. The template and scripts are provided as is with no warranty for issues.