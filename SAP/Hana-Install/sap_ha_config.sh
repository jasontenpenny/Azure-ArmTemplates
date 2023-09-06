#!/bin/bash

# Establish variables
sapInstanceId=$1
sapInstanceIdLower=$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')
sapInstanceNumber=$2
sapUser=${sapInstanceIdLower}adm
sapPassword=$3
#vmPrefix=$4
#otherNode=${vmPrefix}1
thisNode=$HOSTNAME
otherNode=$4
thisNodeIP=$5
otherNodeIP=$6


# Generate SSH Key on local node
expect <<EOF
set timeout 20
spawn sudo ssh-keygen
expect -exact "Enter file in which to save the key (/root/.ssh/id_rsa): "
send "\r"
expect -exact "Enter passphrase (empty for no passphrase): "
send "\r"
expect -exact "Enter same passphrase again: "
send "\r"
expect eof
EOF

# Copy SSH key to other node
expect << EOF
set timeout 60
spawn ssh-copy-id -o StrictHostKeyChecking=no -f root@$otherNode
expect -exact "root@$otherNode\'s password: "
send "$sapPassword\r"
expect eof
EOF


# Connect to other node, generate RSA key, and post back to local node
ssh root@$otherNode "expect <<EOF
set timout 60
spawn sudo ssh-keygen
expect -exact \"Enter file in which to save the key (/root/.ssh/id_rsa): \"
send \"\r\"
expect -exact \"Enter passphrase (empty for no passphrase): \"
send \"\r\"
expect -exact \"Enter same passphrase again: \"
send \"\r\"
expect eof
spawn ssh-copy-id -o StrictHostKeyChecking=no -f root@$thisNode
expect -exact \"root@$thisNode\'s password: \"
send \"$sapPassword\r\"
expect eof
EOF"

sed -i '/DefaultTasksMax/c DefaultTasksMax=4096' /etc/systemd/system.conf
ssh root@$otherNode "sed -i '/DefaultTasksMax/c DefaultTasksMax=4096' /etc/systemd/system.conf"

sudo systemctl daemon-reload
ssh root@$otherNode "sudo systemctl daemon-reload"

sudo printf '%s\n%s\n\n%s\n' 'vm.dirty_bytes = 629145600' 'vm.dirty_background_bytes = 314572800' 'vm.swappiness = 10' >> /etc/sysctl.conf
ssh root@$otherNode "sudo printf '%s\n%s\n\n%s\n' 'vm.dirty_bytes = 629145600' 'vm.dirty_background_bytes = 314572800' 'vm.swappiness = 10' >> /etc/sysctl.conf"

sed -i 's/yes/no/' /etc/sysconfig/network/ifcfg-eth0
ssh root@$otherNode "sed -i 's/yes/no/' /etc/sysconfig/network/ifcfg-eth0"

sudo printf '%s%s%s\n%s%s%s\n' $thisNodeIP ' ' $thisNode $otherNodeIP ' ' $otherNode >> /etc/hosts
ssh root@$otherNode "sudo printf '%s%s%s\n%s%s%s\n' $thisNodeIP ' ' $thisNode $otherNodeIP ' ' $otherNode >> /etc/hosts"