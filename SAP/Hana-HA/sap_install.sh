#!/bin/bash

# Establish variables
sapInstanceId=$1
sapInstanceIdLower=$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')
sapInstanceNumber=$2
sapUser=${sapInstanceIdLower}adm
sapPassword=$3
installSource=$4
installSourceFile=$5

# Set up log file
set -v -x -E
log_file="/tmp/$(hostname)_sapInstall_$(date +%Y-%m-%d_%H-%M-%S).log"

# Make Download directory
sudo mkdir /hana/shared/$sapInstanceId/download
sudo mkdir /hana/shared/$sapInstanceId/download/sapsoftware

# Copy SAP Installer from storage location
sudo wget -O /hana/shared/$sapInstanceId/download/sapsoftware/$installSourceFile $installSource

# Make install directory
sudo mkdir /hana/shared/$sapInstanceId/download/hanainstall

# Extract installer
sudo unzip -d /hana/shared/$sapInstanceId/download/hanainstall /hana/shared/$sapInstanceId/download/sapsoftware/$installSourceFile

# Permissions fix on the installation media
chmod +x /hana/shared/$sapInstanceId/download/hanainstall/DATA_UNITS/HDB_SERVER_LINUX_X86_64

# Install prereqs
sudo zypper -n install libgcc_s1 libstdc++6 libatomic1 insserv-compat libtool

# Launch the SAP Installer and proceed through the config questions
expect <<EOF
set timeout -1
spawn /hana/shared/$sapInstanceId/download/hanainstall/DATA_UNITS/HDB_SERVER_LINUX_X86_64/hdblcm --ignore=check_signature_file
expect -exact "Enter selected action index \[4\]: "
send "1\r"
expect -exact "Enter comma-separated list of the selected indices \[3,4\]: "
send "2,3\r"
expect -exact "Enter Installation Path \[/hana/shared\]: "
send "/hana/shared\r"
expect -exact "Enter Local Host Name \[$HOSTNAME\]: "
send "$HOSTNAME\r"
expect -exact "Do you want to add hosts to the system? (y/n) \[n\]: "
send "n\r"
expect -exact "Enter SAP HANA System ID: "
send "$sapInstanceId\r"
expect -exact "Enter Instance Number \[00\]: "
send "$sapInstanceNumber\r"
expect -exact "Enter Local Host Worker Group \[default\]: "
send "\r"
expect -exact "Select System Usage / Enter Index \[4\]: "
send "2\r"
expect -exact "Do you want to enable backup encryption? \[y\]: "
send "n\r"
expect -exact "Do you want to enable data and log volume encryption? \[y\]: "
send "n\r"
expect -exact "Enter Location of Data Volumes \[/hana/data/$sapInstanceId\]: "
send "/hana/data/$sapInstanceId\r"
expect -exact "Enter Location of Log Volumes \[/hana/log/$sapInstanceId\]: "
send "/hana/log/$sapInstanceId\r"
expect -exact "Restrict maximum memory allocation? \[n\]: "
send "n\r"
expect -exact "Apply System Size Dependent Resource Limits? (SAP Note 3014176) \[y\]: "
send "y\r"
expect -exact "Enter SAP Host Agent User (sapadm) Password: "
send "$sapPassword\r"
expect -exact "Confirm SAP Host Agent User (sapadm) Password: "
send "$sapPassword\r"
expect -exact "Enter System Administrator ($sapUser) Password: "
send "$sapPassword\r"
expect -exact "Confirm System Administrator ($sapUser) Password: "
send "$sapPassword\r"
expect -exact "Enter System Administrator Home Directory \[/usr/sap/$sapInstanceId/home\]: "
send "/usr/sap/$sapInstanceId/home\r"
expect -exact "Enter System Administrator Login Shell \[/bin/sh\]: "
send "\r"
expect -exact "Enter System Administrator User ID \[1001\]: "
send "\r"
expect -exact "Enter ID of User Group (sapsys) \[79\]: "
send "\r"
expect -exact "Enter System Database User (SYSTEM) Password: "
send "$sapPassword\r"
expect -exact "Confirm System Database User (SYSTEM) Password: "
send "$sapPassword\r"
expect -exact "Restart system after machine reboot? \[n]\: "
send "n\r"
expect -exact "Do you want to continue? (y/n): "
send "y\r"
expect -exact "SAP HANA Database System installed\r"
expect eof
EOF