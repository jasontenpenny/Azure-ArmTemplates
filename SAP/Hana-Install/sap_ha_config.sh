#!/bin/bash

# Establish variables
sapInstanceId=$1
sapInstanceIdLower=$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')
sapInstanceNumber=$2
sapUser=${sapInstanceIdLower}adm
sapPassword=$3
thisNode=$HOSTNAME
otherNode=$4
thisNodeIP=$(ip -4 -o a show eth0 | cut -d ' ' -f 7 | cut -d '/' -f 1)
subId=$5
resourceGroup=$6
ilbIP=$7


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

otherNodeIP=$(ssh root@$otherNode "ip -4 -o a show eth0 | cut -d ' ' -f 7 | cut -d '/' -f 1")

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

expect << EOF
set timeout 60
spawn sudo crm cluster init
expect -exact "Continue (y/n)? "
send "y\r"
expect -exact "Address for ring0 \[$thisNodeIP\]"
send "$thisNodeIP\r"
expect -exact "Port for ring0 \[5405\]"
send "\r"
expect -exact "Do you wish to use SBD (y/n)? "
send "n\r"
expect -exact "Do you wish to configure a virtual IP address (y/n)? "
send "n\r"
expect -exact "Do you want to configure QDevice (y/n)? "
send "n\r"
expect eof
EOF

ssh root@$otherNode "expect << EOF
set timeout 60
spawn sudo crm cluster join
expect -exact \"IP address or hostname of existing node (e.g.: 192.168.1.1) \[\]\"
send \"$thisNodeIP\"
expect -exact \"Continue (y/n)? \"
send \"y\r\"
expect -exact \"Address for ring0 \[$otherNodeIP\]\"
send \"$otherNodeIP\r\"
expect eof
EOF"

echo hacluster:"$sapPassword" | chpasswd
ssh root@$otherNode "echo hacluster:\"$sapPassword\" | chpasswd"

sudo sed -i 's/token_retransmits_before_loss_const: 10/&\n        consensus: 36000' /etc/corosync/corosync.conf
sudo service corosync restart
ssh root@$otherNode "sed -i 's/token_retransmits_before_loss_const:\ 10/&\n\ \ \ \ \ \ \ \ consensus:\ 36000/' /etc/corosync/corosync.conf"
ssh root@$otherNode "sudo service corosync restart"


sudo crm configure property stonith-enabled=true
sudo crm configure property concurrent-fencing=true
sudo crm configure primitive rsc_st_azure stonith:fence_azure_arm \
params msi=true subscriptionId="$subId" resourceGroup="$resourceGroup" \
pcmk_monitor_retries=4 pcmk_action_limit=3 power_timeout=240 pcmk_reboot_timeout=900 \
op monitor interval=3600 timeout=120
sudo crm configure property stonith-timeout=900

sudo crm configure property maintenance-mode=true
sudo crm configure primitive rsc_azure-events ocf:heartbeat:azure-events op monitor interval=10s
sudo crm configure clone cln_azure-events rsc_azure-events
sudo crm configure property maintenance-mode=false

sleep 90

sudo zypper -n install SAPHanaSR
ssh root@$otherNode "sudo zypper -n install SAPHanaSR"

su - $sapUser -c "HDB start"
su - $sapUser -c "hdbsql -d SYSTEMDB -u SYSTEM -p \"$sapPassword\" -i $sapInstanceNumber \"BACKUP DATA USING FILE ('initialbackupSYS')\""
su - $sapUser -c "hdbsql -d $sapInstanceId -u SYSTEM -p \"$sapPassword\" -i $sapInstanceNumber \"BACKUP DATA USING FILE ('initialbackup$sapInstanceId')\""

# Copy key info to other node
sudo scp -o StrictHostKeyChecking=no /usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/data/SSFS_$sapInstanceId.DAT $otherNode:/usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/data/
sudo scp -o StrictHostKeyChecking=no /usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/key/SSFS_$sapInstanceId.KEY $otherNode:/usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/key/

# Register node 1 in SAP Hana SR
su - $sapUser -c "hdbnsutil -sr_enable --name=SITE1"

# Register node 2 in SAP Hana SR
ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StopWait 600 10\""
ssh root@$otherNode "su - $sapUser -c \"hdbnsutil -sr_register --remoteHost=$thisNode --remoteInstance=$sapInstanceNumber --replicationMode=sync --name=SITE2\""

su - $sapUser -c "sapcontrol -nr $sapInstanceNumber -function StopSystem"

sudo printf '\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n' '[ha_dr_provider_SAPHanaSR]' 'provider = SAPHanaSR' 'path = /usr/share/SAPHanaSR' 'execution_order = 1' '[ha_dr_provider_suschksrv]' 'provider = susChkSrv' 'path = /usr/share/SAPHanaSR' 'execution_order = 3' 'action_on_lost = fence' '[trace]' 'ha_dr_saphanasr = info' >> /hana/shared/$sapInstanceId/global/hdb/custom/config/global.ini

ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StopSystem\""
ssh root@$otherNode "sudo printf '\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n' '[ha_dr_provider_SAPHanaSR]' 'provider = SAPHanaSR' 'path = /usr/share/SAPHanaSR' 'execution_order = 1' '[ha_dr_provider_suschksrv]' 'provider = susChkSrv' 'path = /usr/share/SAPHanaSR' 'execution_order = 3' 'action_on_lost = fence' '[trace]' 'ha_dr_saphanasr = info' >> /hana/shared/$sapInstanceId/global/hdb/custom/config/global.ini"


sudo printf '%s\n%s\n%s\n' '# Needed for SAPHanaSR and susChkSrv Python hooks' "$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_${sapInstanceId}_site_srHook_*" "$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper --sid=$sapInstanceId --case=fenceMe" >> /etc/sudoers.d/20-saphana

ssh root@$otherNode "sudo printf '%s\n%s\n%s\n' '# Needed for SAPHanaSR and susChkSrv Python hooks' \"$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_${sapInstanceId}_site_srHook_*\" \"$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper --sid=$sapInstanceId --case=fenceMe\" >> /etc/sudoers.d/20-saphana"

su - $sapUser -c "sapcontrol -nr $sapInstanceNumber -function StartSystem"
ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StartSystem\""


# Configure Pacemaker Cluster Resources
sudo crm configure property maintenance-mode=true

sudo crm configure primitive rsc_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} ocf:suse:SAPHanaTopology \
operations \$id="rsc_sap2_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op monitor interval="10" timeout="600" \
op start interval="0" timeout="600" \
op stop interval="0" timeout="300" \
params SID="$sapInstanceId" InstanceNumber="$sapInstanceNumber"

sudo crm configure clone cln_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} rsc_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} \
meta clone-node-max="1" target-role="Started" interleave="true"

sudo crm configure primitive rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} ocf:suse:SAPHana \
operations \$id="rsc_sap_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op start interval="0" timeout="3600" \
op stop interval="0" timeout="3600" \
op promote interval="0" timeout="3600" \
op monitor interval="60" role="Master" timeout="700" \
op monitor interval="61" role="Slave" timeout="700" \
params SID="$sapInstanceId" InstanceNumber="$sapInstanceNumber" PREFER_SITE_TAKEOVER="true" \
DUPLICATE_PRIMARY_TIMEOUT="7200" AUTOMATED_REGISTER="true"

sudo crm configure ms msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} \
meta notify="true" clone-max="2" clone-node-max="1" \
target-role="Started" interleave="true"

sudo crm configure primitive rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber} ocf:heartbeat:IPaddr2 \
meta target-role="Started" \
operations \$id="rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op monitor interval="10s" timeout="20s" \
params ip="$ilbIP"
# !!!!!!! I have to figure out how to find the ILB IP !!!!!!!!!

sudo crm configure primitive rsc_nc_${sapInstanceId}_HDB${sapInstanceNumber} azure-lb port=625${sapInstanceNumber} \
op monitor timeout=20s interval=10 \
meta resource-stickiness=0

sudo crm configure group g_ip_${sapInstanceId}_HDB${sapInstanceNumber} rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber} rsc_nc_${sapInstanceId}_HDB${sapInstanceNumber}

sudo crm configure colocation col_saphana_ip_${sapInstanceId}_HDB${sapInstanceNumber} 4000: g_ip_${sapInstanceId}_HDB${sapInstanceNumber}:Started \
msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber}:Master

sudo crm configure order ord_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} Optional: cln_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} \
msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber}

sudo crm resource cleanup rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber}

sudo crm configure property maintenance-mode=false

sudo crm configure rsc_defaults resource-stickiness=1000
sudo crm configure rsc_defaults migration-threshold=5000
