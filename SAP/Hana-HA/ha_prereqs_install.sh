#!/bin/bash

sudo zypper -n install socat
sudo zypper -n install resource-agents
sudo zypper -n install fence-agents
sudo zypper -n install python3-azure-mgmt-compute
sudo zypper -n install python3-azure-identity
sudo zypper -n update

sudo reboot