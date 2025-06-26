#!/bin/bash
# Post-install LVM configuration

# Prepare partition 3 for LVM
wipefs -a /dev/nvme0n1p3
partprobe /dev/nvme0n1

# Create physical volume
pvcreate /dev/nvme0n1p3

# Create volume group
vgcreate ubuntu-vg /dev/nvme0n1p3

# Create logical volumes
lvcreate -L 50G -n root ubuntu-vg
lvcreate -L 30G -n home ubuntu-vg
lvcreate -L 150G -n docker ubuntu-vg
lvcreate -L 100G -n libvirt ubuntu-vg

# Format filesystems
mkfs.ext4 /dev/ubuntu-vg/root
mkfs.ext4 /dev/ubuntu-vg/home
mkfs.ext4 /dev/ubuntu-vg/docker
mkfs.ext4 /dev/ubuntu-vg/libvirt

# Mount new volumes
mount /dev/ubuntu-vg/root /mnt
mkdir -p /mnt/{home,var/lib/docker,var/lib/libvirt}
mount /dev/ubuntu-vg/home /mnt/home
mount /dev/ubuntu-vg/docker /mnt/var/lib/docker
mount /dev/ubuntu-vg/libvirt /mnt/var/lib/libvirt

# Migrate OS to LVM
rsync -aAX / /mnt --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*"}
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run

# Chroot and update bootloader
chroot /mnt <<EOF
mount /dev/nvme0n1p2 /boot
mount /dev/nvme0n1p1 /boot/efi
update-initramfs -u
update-grub
EOF

# Update fstab
cat > /mnt/etc/fstab <<EOF
/dev/ubuntu-vg/root    /         ext4    defaults        0 1
/dev/ubuntu-vg/home    /home     ext4    defaults        0 2
/dev/ubuntu-vg/docker  /var/lib/docker  ext4 defaults   0 2
/dev/ubuntu-vg/libvirt /var/lib/libvirt ext4 defaults   0 2
/dev/nvme0n1p2         /boot     ext4    defaults        0 2
/dev/nvme0n1p1         /boot/efi vfat    umask=0077     0 1
EOF

# Reboot into new system
reboot
