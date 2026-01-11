# EmergencyBox Installation Guide

> **IMPORTANT UPDATE**: For DD-WRT auto-start configuration, see **[AUTOSTART_SETUP.md](../AUTOSTART_SETUP.md)** which includes the `mount --bind` fix for read-only filesystem issues.

This guide covers installing EmergencyBox on an ASUS RT-AC68U router running either Asuswrt-Merlin or DD-WRT firmware.

## Prerequisites

- ASUS RT-AC68U router
- SSH access to the router
- USB storage device (recommended: 8GB+ for file storage)
- Basic knowledge of Linux command line


## Option 1: DD-WRT Installation

### Step 1: Install DD-WRT Firmware

1. Download DD-WRT for RT-AC68U:
   https://dd-wrt.com/support/router-database/

2. Flash firmware via router web interface
3. Factory reset after flashing

### Step 2: Enable USB Support and Optware

1. Go to Services > USB
2. Enable Core USB Support
3. Enable USB Storage Support
4. Apply settings

### Step 3: Install Optware/Entware

```bash
# SSH into router
ssh root@192.168.1.1

# Install Entware (DD-WRT version)
wget http://bin.entware.net/armv7sf-k3.2/installer/generic.sh
sh generic.sh

# Update
opkg update
opkg upgrade
```

### Step 4: Install Packages

DD-WRT typically has better PHP support:

```bash
# Install packages
opkg install php7 php7-cgi php7-mod-sqlite3 php7-mod-fileinfo
opkg install lighttpd lighttpd-mod-fastcgi
opkg install sqlite3-cli

# Verify
php -v
```

### Step 5: Deploy EmergencyBox Files

```bash
# Create web directory
mkdir -p /opt/share/www
mkdir -p /opt/share/www/uploads/{emergency,media,documents,general}
mkdir -p /opt/share/data

# Copy EmergencyBox files to router
# From your computer, use SCP:
scp -r www/* admin@192.168.1.1:/opt/share/www/
scp -r config/* admin@192.168.1.1:/opt/etc/

# Set permissions
chmod -R 755 /opt/share/www
chmod -R 777 /opt/share/www/uploads
chmod -R 755 /opt/share/data
```

### Step 6: Configure lighttpd

```bash
# Backup original config
cp /opt/etc/lighttpd/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf.bak

# Copy EmergencyBox config
cp /opt/etc/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf

# Adjust paths if needed
vi /opt/etc/lighttpd/lighttpd.conf
```

### Step 7: Configure PHP

```bash
# Copy PHP configuration
cp /opt/etc/php.ini /opt/etc/php.ini

# Verify max upload settings
grep upload_max_filesize /opt/etc/php.ini
grep post_max_size /opt/etc/php.ini
```

### Step 8: Initialize Database

```bash
# Run database initialization
php /opt/share/www/api/init_db.php

# Verify database was created
ls -lh /opt/share/data/emergencybox.db
```

### Step 9: Start Services

```bash
# Start lighttpd
/opt/etc/init.d/S80lighttpd start

# Check if running
ps | grep lighttpd

# Check logs
tail -f /opt/var/log/lighttpd/error.log
```

### Step 10: Configure Autostart

Create startup script:
```bash
vi /jffs/scripts/post-mount

# Add the following:
#!/bin/sh
sleep 5
/opt/etc/init.d/S80lighttpd start
```

Make it executable:
```bash
chmod +x /jffs/scripts/post-mount
```

### Step 11: Test Installation

1. Connect to your router's WiFi network
2. Open browser and navigate to: http://192.168.1.1
3. You should see the EmergencyBox interface
4. Test chat functionality
5. Test file upload (start with small file)
6. Test large file upload (5GB test)

---

## Troubleshooting

### PHP Not Available in Entware

**Problem:** No PHP packages in `opkg list`

**Solutions:**
1. **Use DD-WRT instead** - DD-WRT typically has better package support
2. **Compile PHP manually** - Advanced users only
3. **Use alternative backend** - Consider Python/Flask or Node.js alternatives

### Large File Upload Fails

**Problem:** Uploads fail for files >100MB

**Check:**
1. PHP settings in `/opt/etc/php.ini`:
   - `upload_max_filesize = 5G`
   - `post_max_size = 5G`
   - `max_execution_time = 600`
   - `max_input_time = 600`
   - `memory_limit = 256M`

2. lighttpd settings in `/opt/etc/lighttpd/lighttpd.conf`:
   - `server.max-request-size = 5368709120`
   - `server.max-write-idle = 600`

3. Restart services:
   ```bash
   /opt/etc/init.d/S80lighttpd restart
   ```

### Database Errors

**Problem:** SQLite errors or missing database

**Solution:**
```bash
# Recreate database
rm /opt/share/data/emergencybox.db
php /opt/share/www/api/init_db.php

# Check permissions
chmod 755 /opt/share/data
chmod 644 /opt/share/data/emergencybox.db
```


## Option 2: Asuswrt-Merlin Installation

### Step 1: Install Asuswrt-Merlin Firmware

1. Download the latest Asuswrt-Merlin firmware for RT-AC68U from:
   [https://www.asuswrt-merlin.net/download]

2. Flash the firmware through the router's web interface:
   - Login to router admin panel (usually http://192.168.1.1)
   - Go to Administration > Firmware Upgrade
   - Upload the .trx or .w file
   - Wait for reboot (5-10 minutes)

### Step 2: Enable SSH and JFFS

1. Login to router web interface
2. Go to Administration > System
3. Enable SSH: Set to "LAN only"
4. Enable JFFS custom scripts and configs
5. Apply settings

### Step 3: Install Entware

SSH into your router:
```bash
ssh admin@192.168.1.1
```

Install Entware:
```bash
# Mount USB drive (if not already mounted)
# The USB drive should be formatted as ext4 for best compatibility

# Download and run Entware installer
wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh

# Update package list
opkg update
```

### Step 4: Install Required Packages

**CRITICAL: PHP Version Compatibility**

The RT-AC68U runs on an ARM architecture. You need to verify which PHP version is available for your kernel:

```bash
# Check your kernel version
uname -r

# List available PHP packages
opkg list | grep php
```

**For Asuswrt-Merlin (kernel 2.6.36.4):**

If PHP 7.x or 8.x is not available in Entware, you have two options:

**Option A: Use available PHP version**
```bash
# Install whatever PHP version is available
opkg install php7-cli php7-cgi php7-mod-sqlite3 php7-mod-fileinfo

# OR if PHP 8 is available
opkg install php8-cli php8-cgi php8-mod-sqlite3 php8-mod-fileinfo
```

**Option B: Manual PHP Installation**

If Entware has no PHP packages, you'll need to compile PHP manually or use a pre-compiled binary:

```bash
# This is complex and not recommended unless necessary
# Consider switching to DD-WRT instead (see Option 1)
```

**Install web server and other dependencies:**

```bash
# Install lighttpd
opkg install lighttpd lighttpd-mod-fastcgi

# Install SQLite3
opkg install sqlite3-cli

# Verify installations
php -v
lighttpd -v
sqlite3 -version
```

### Step 5: Deploy EmergencyBox Files

```bash
# Create web directory
mkdir -p /opt/share/www
mkdir -p /opt/share/www/uploads/{emergency,media,documents,general}
mkdir -p /opt/share/data

# Copy EmergencyBox files to router
# From your computer, use SCP:
scp -r www/* admin@192.168.1.1:/opt/share/www/
scp -r config/* admin@192.168.1.1:/opt/etc/

# Set permissions
chmod -R 755 /opt/share/www
chmod -R 777 /opt/share/www/uploads
chmod -R 755 /opt/share/data
```

### Step 6: Configure lighttpd

```bash
# Backup original config
cp /opt/etc/lighttpd/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf.bak

# Copy EmergencyBox config
cp /opt/etc/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf

# Adjust paths if needed
vi /opt/etc/lighttpd/lighttpd.conf
```

### Step 7: Configure PHP

```bash
# Copy PHP configuration
cp /opt/etc/php.ini /opt/etc/php.ini

# Verify max upload settings
grep upload_max_filesize /opt/etc/php.ini
grep post_max_size /opt/etc/php.ini
```

### Step 8: Initialize Database

```bash
# Run database initialization
php /opt/share/www/api/init_db.php

# Verify database was created
ls -lh /opt/share/data/emergencybox.db
```

### Step 9: Start Services

```bash
# Start lighttpd
/opt/etc/init.d/S80lighttpd start

# Check if running
ps | grep lighttpd

# Check logs
tail -f /opt/var/log/lighttpd/error.log
```

### Step 10: Configure Autostart

Create startup script:
```bash
vi /jffs/scripts/post-mount

# Add the following:
#!/bin/sh
sleep 5
/opt/etc/init.d/S80lighttpd start
```

Make it executable:
```bash
chmod +x /jffs/scripts/post-mount
```

### Step 11: Test Installation

1. Connect to your router's WiFi network
2. Open browser and navigate to: http://192.168.1.1
3. You should see the EmergencyBox interface
4. Test chat functionality
5. Test file upload (start with small file)
6. Test large file upload (5GB test)

---



### Out of Memory

**Problem:** Router crashes or services stop during large uploads

**Solutions:**
1. Increase swap space on USB drive
2. Reduce PHP memory_limit
3. Limit concurrent uploads
4. Use a larger USB drive

### Services Don't Start on Boot

**Problem:** EmergencyBox not available after router reboot

**Solution:**
```bash
# Check post-mount script
cat /jffs/scripts/post-mount

# Ensure it's executable
chmod +x /jffs/scripts/post-mount

# Test manually
/jffs/scripts/post-mount
```

---

## Performance Optimization

### For Better Upload Speed

1. Use USB 3.0 drive if supported
2. Format USB as ext4 (not FAT32)
3. Enable jumbo frames if all devices support it
4. Disable unnecessary services on router

### For More Concurrent Users

Edit `/opt/etc/lighttpd/lighttpd.conf`:
```
server.max-connections = 100  # Increase from 50
server.max-fds = 512           # Increase from 256
```

Edit `/opt/etc/php.ini`:
```
PHP_FCGI_CHILDREN = 4          # Increase from 2
```

---

## Security Considerations

Since EmergencyBox is designed for **offline disaster scenarios**:

1. **Change default router password** - Always use a strong password
2. **Disable WAN access** - Only allow LAN connections
3. **Use WPA2 encryption** - Secure the WiFi network
4. **Regular backups** - Backup the SQLite database periodically
5. **File scanning** - Be aware that uploaded files are not scanned for malware

---

## Maintenance

### Backup Database

```bash
# Copy database to USB
cp /opt/share/data/emergencybox.db /mnt/usb/backups/

# Or download via SCP
scp admin@192.168.1.1:/opt/share/data/emergencybox.db ./backup.db
```

### Clear Old Files

```bash
# Find files older than 30 days
find /opt/share/www/uploads -type f -mtime +30

# Delete if needed
find /opt/share/www/uploads -type f -mtime +30 -delete
```

### Monitor Storage

```bash
# Check disk usage
df -h

# Check upload folder size
du -sh /opt/share/www/uploads
```

---

## Next Steps

- See [USAGE.md](USAGE.md) for user guide
- See [DEVELOPMENT.md](DEVELOPMENT.md) for customization
- See [BACKUP.md](BACKUP.md) for backup strategies
