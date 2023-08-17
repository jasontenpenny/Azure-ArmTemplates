#!/bin/bash

# Establish variables
sapInstanceId=$1
sapPassword=$2

# Set root password
echo root:$sapPassword | chpasswd

# Create physical volumes for each lun
sudo pvcreate /dev/disk/azure/scsi1/lun0
sudo pvcreate /dev/disk/azure/scsi1/lun1
sudo pvcreate /dev/disk/azure/scsi1/lun2
sudo pvcreate /dev/disk/azure/scsi1/lun3
sudo pvcreate /dev/disk/azure/scsi1/lun4
sudo pvcreate /dev/disk/azure/scsi1/lun5
sudo pvcreate /dev/disk/azure/scsi1/lun6

# Create volume groups
sudo vgcreate vg_hana_data_$sapInstanceId /dev/disk/azure/scsi1/lun0 /dev/disk/azure/scsi1/lun1 /dev/disk/azure/scsi1/lun2 /dev/disk/azure/scsi1/lun3
sudo vgcreate vg_hana_shared_$sapInstanceId /dev/disk/azure/scsi1/lun4
sudo vgcreate vg_hana_shared_usrsap_$sapInstanceId /dev/disk/azure/scsi1/lun5
sudo vgcreate vg_hana_log_$sapInstanceId /dev/disk/azure/scsi1/lun6

# Creates logical volumes
sudo lvcreate -i 4 -I 256 -l 100%FREE -n hana_data vg_hana_data_$sapInstanceId
sudo lvcreate -l 100%FREE -n hana_shared vg_hana_shared_$sapInstanceId
sudo lvcreate -l 100%FREE -n hana_usrsap vg_hana_shared_usrsap_$sapInstanceId
sudo lvcreate -l 100%FREE -n hana_log vg_hana_log_$sapInstanceId

# Creates a file system on each drive
sudo mkfs.xfs /dev/vg_hana_data_$sapInstanceId/hana_data
sudo mkfs.xfs /dev/vg_hana_shared_$sapInstanceId/hana_shared
sudo mkfs.xfs /dev/vg_hana_shared_usrsap_$sapInstanceId/hana_usrsap
sudo mkfs.xfs /dev/vg_hana_log_$sapInstanceId/hana_log

# Creates the directories
sudo mkdir -p /hana/data/$sapInstanceId
sudo mkdir -p /hana/shared/$sapInstanceId
sudo mkdir -p /usr/sap/$sapInstanceId
sudo mkdir -p /hana/log/$sapInstanceId

# Extract UUIDs for each of the new drives
dataUUID=$(sudo blkid|grep /dev/mapper/vg_hana_data_$sapInstanceId-hana_data|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
sharedUUID=$(sudo blkid|grep /dev/mapper/vg_hana_shared_$sapInstanceId-hana_shared|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
usrsapUUID=$(sudo blkid|grep /dev/mapper/vg_hana_shared_usrsap_$sapInstanceId-hana_usrsap|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
logUUID=$(sudo blkid|grep /dev/mapper/vg_hana_log_$sapInstanceId-hana_log|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")

# Adds each disk to fstab
echo "/dev/disk/by-uuid/$dataUUID /hana/data/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$sharedUUID /hana/shared/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$usrsapUUID /usr/sap/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$logUUID /hana/log/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab

# Mounts the new disks
sudo mount -a

