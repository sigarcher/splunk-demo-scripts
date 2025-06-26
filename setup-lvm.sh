#!/bin/bash
# LVM Configuration for Splunk Demo Environment

# Create physical volume
pvcreate /dev/nvme0n1p3

# Create volume group
vgcreate ubuntu-vg /dev/nvme0n1p3

# Create logical volumes
lvcreate -L 50G -n root ubuntu-vg
lvcreate -L 50G -n home ubuntu-vg
lvcreate -L 200G -n splunk ubuntu-vg
lvcreate -L 150G -n docker ubuntu-vg
lvcreate -L 100G -n libvirt ubuntu-vg
lvcreate -L 400G -n thin-pool ubuntu-vg

# Format filesystems
mkfs.ext4 /dev/ubuntu-vg/root
mkfs.ext4 /dev/ubuntu-vg/home
mkfs.ext4 /dev/ubuntu-vg/splunk
mkfs.ext4 /dev/ubuntu-vg/docker
mkfs.ext4 /dev/ubuntu-vg/libvirt

# Create mount points
mkdir -p /opt/splunk /var/lib/docker /var/lib/libvirt

# Configure fstab
cat >> /etc/fstab << EOF
/dev/ubuntu-vg/root / ext4 defaults 0 1
/dev/ubuntu-vg/home /home ext4 defaults 0 2
/dev/ubuntu-vg/splunk /opt/splunk ext4 defaults 0 2
/dev/ubuntu-vg/docker /var/lib/docker ext4 defaults 0 2
/dev/ubuntu-vg/libvirt /var/lib/libvirt ext4 defaults 0 2
EOF

# Mount all filesystems
mount -a
