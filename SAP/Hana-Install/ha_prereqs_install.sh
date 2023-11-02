#!/bin/bash

# Set up log file
set -v -x -E
logFile="/tmp/$(hostname)_haPrereqs_$(date +%Y-%m-%d_%H-%M-%S).log"

echo "<<< install socat >>>" >> $logFile
sudo zypper -n install socat | tee -i -a "$logFile"
echo "<<< install resource-agents >>>" >> $logFile
sudo zypper -n install resource-agents | tee -i -a "$logFile"
echo "<<< install fence-agents >>>" >> $logFile
sudo zypper -n install fence-agents | tee -i -a "$logFile"
echo "<<< install python3-azure-mgmt-compute >>>" >> $logFile
sudo zypper -n install python3-azure-mgmt-compute | tee -i -a "$logFile"
echo "<<< install python3-azure-identity >>>" >> $logFile
sudo zypper -n install python3-azure-identity | tee -i -a "$logFile"
echo "<<< perform zypper update >>>" >> $logFile
sudo zypper -n update | tee -i -a "$logFile"

echo "<<< reboot VM >>>" >> $logFile
sudo shutdown -r