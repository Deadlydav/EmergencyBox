#!/bin/sh
# EmergencyBox Auto-Start Script for DD-WRT
# This script should be added to DD-WRT via Web Interface:
# Administration → Commands → Startup → Save Startup

# Wait for system to fully boot
sleep 5

# Wait for USB devices to be detected
while [ ! -b /dev/sda2 ]; do sleep 1; done

# Create mount points
mkdir -p /tmp/mnt/sda1 /tmp/mnt/sda2

# Mount USB partitions (if not already mounted by automount)
mount /dev/sda2 /tmp/mnt/sda2 2>/dev/null
mount /dev/sda1 /tmp/mnt/sda1 2>/dev/null

# KEY FIX: Use mount --bind to overlay /opt directory
# This works even when root filesystem is read-only
mount --bind /tmp/mnt/sda2 /opt

# Create symlink for web files
mkdir -p /opt/share
ln -sfn /tmp/mnt/sda1/www /opt/share/www

# Start Entware services
/opt/etc/init.d/rc.unslung start

# Wait for services to initialize
sleep 3

# Start lighttpd web server
/opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf &

# EmergencyBox should now be accessible at http://192.168.1.1:8080
