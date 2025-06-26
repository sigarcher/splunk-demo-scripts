#!/bin/bash
# Updated LVM setup script with safeguards

# Wipe filesystem signatures (forcefully)
echo "Wiping filesystem signatures..."
sudo wipefs -a /dev/nvme0n1p3 || {
    echo "Wipe failed, using dd fallback..."
    sudo dd if=/dev/zero of=/dev/nvme0n1p3 bs=1M count=10
}

# Create physical volume
echo "Creating physical volume..."
sudo pvcreate /dev/nvme0n1p3

# Create volume group
echo "Creating volume group..."
sudo vgcreate ubuntu-vg /dev/nvme0n1p3

# Create logical volumes
echo "Creating logical volumes..."
sudo lvcreate -L 50G -n root ubuntu-vg
sudo lvcreate -L 50G -n home ubuntu-vg
sudo lvcreate -L 200G -n splunk ubuntu-vg
sudo lvcreate -L 150G -n docker ubuntu-vg
sudo lvcreate -L 100G -n libvirt ubuntu-vg
sudo lvcreate -L 400G -n thin-pool ubuntu-vg

# Format filesystems
echo "Formatting filesystems..."
sudo mkfs.ext4 /dev/ubuntu-vg/root
sudo mkfs.ext4 /dev/ubuntu-vg/home
sudo mkfs.ext4 /dev/ubuntu-vg/splunk
sudo mkfs.ext4 /dev/ubuntu-vg/docker
sudo mkfs.ext4 /dev/ubuntu-vg/libvirt

# Create mount points
echo "Creating mount points..."
sudo mkdir -p /opt/splunk /var/lib/docker /var/lib/libvirt

# Configure fstab
echo "Updating fstab..."
sudo tee -a /etc/fstab << EOF
/dev/ubuntu-vg/root    /         ext4    defaults        0 1
/dev/ubuntu-vg/home    /home     ext4    defaults        0 2
/dev/ubuntu-vg/splunk  /opt/splunk ext4 defaults        0 2
/dev/ubuntu-vg/docker  /var/lib/docker ext4 defaults    0 2
/dev/ubuntu-vg/libvirt /var/lib/libvirt ext4 defaults   0 2
EOF

# Mount filesystems
echo "Mounting filesystems..."
sudo mount -a

echo "LVM setup completed successfully!"
