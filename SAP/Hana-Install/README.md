# SAP Hana HDB HA Environment

This script is similar to the one under the Hana-HA folder, except that it assumes that your infrastructure has already been deployed. You must specify existing VMs to deploy on, and must provide a resource ID for the Azure Load Balancer.

You can optionally trigger an automated installation of SAP Hana. If you already have Hana installed, you can skip this step and proceed to HA configuration. This process assumes that the installation media has previously been downloaded and stored in an Azure Storage account as a blob file. This file must be publically accessible without authentication (anonymous).

Regardless of whether you installed Hana with this script, you can utilize it to perform an automatic configuration of the high availability components: a Hana database cluster utilizing Pacemaker and Hana System Replication.

# Disclaimer

This template and associated scripts is **not** suited for use in a production environment! The goal of this deployment template is to speed up the process of building a test environment for learning more about SAP Hana. The template and scripts are provided as is with no warranty for issues.