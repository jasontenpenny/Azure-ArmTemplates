#!/bin/bash

sudo zypper -n install socat resource-agents fence-agents python3-azure-mgmt-compute python3-azure-identity
sudo zypper -n update

sudo reboot -now