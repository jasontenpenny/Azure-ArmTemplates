#!/bin/bash

# Establish variables
sapInstanceId=$1
sapInstanceIdLower=$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')
sapInstanceNumber=$2
sapUser=${sapInstanceIdLower}adm
sapPassword=$3
#vmPrefix=$4
#otherNode=${vmPrefix}1
otherNode=$4

#function defineOtherNode() {
#    if [ "$HOSTNAME" -eq "$otherNode" ]; then
#        $otherNode=${vmPrefix}2
#    fi
#
#}

#defineOtherNode

sed -i '/DefaultTasksMax/c DefaultTasksMax=4096' /etc/systemd/system.conf

sudo printf '%s\n%s\n\n%s\n' 'vm.dirty_bytes = 629145600' 'vm.dirty_background_bytes = 314572800' 'vm.swappiness = 10' >> /etc/sysctl.conf

sed -i 's/yes/no/' /etc/sysconfig/network/ifcfg-eth0

expect <<EOF
set timeout -1
spawn sudo ssh-keygen
expect -exact "Enter file in which to save the key (/root/.ssh/id_rsa): "
send "\r"
expect -exact "Enter passphrase (empty for no passphrase): "
send "\r"
expect -exact "Enter same passphrase again: "
send "\r"
expect eof
EOF