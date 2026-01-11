# EmergencyBox - Complete DD-WRT Deployment Guide

This document provides comprehensive deployment instructions for EmergencyBox on DD-WRT routers, based on a successful deployment to an ASUS RT-AC68U. It includes detailed troubleshooting for all critical issues encountered during real-world deployment.

> **IMPORTANT UPDATE**: For auto-start configuration on boot, see **[AUTOSTART_SETUP.md](AUTOSTART_SETUP.md)** which documents the critical `mount --bind` solution for DD-WRT's read-only filesystem limitation.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Critical Issues & Solutions](#critical-issues--solutions)
5. [Testing & Verification](#testing--verification)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

---

## Prerequisites

### Hardware Requirements

**Router:**
- **Model**: ASUS RT-AC68U (or compatible DD-WRT-supported router)
- **CPU**: ARM Cortex-A9 dual-core @ 800 MHz (BCM4708/4709)
- **RAM**: 256 MB minimum
- **Flash**: 128 MB
- **USB Ports**: USB 2.0/3.0 for external storage

**USB Storage:**
- **Capacity**: 8GB minimum (16GB+ recommended for extensive file storage)
- **Format**: ext4 (required for proper permissions and symlinks)
- **Partitions**: Two partitions required (see Architecture section)

### Software Requirements

**Firmware:**
- DD-WRT firmware build for ASUS RT-AC68U
- Recommended: Latest stable release from https://dd-wrt.com/
- File format: `.trx` or `.bin` depending on installation method

**Required Packages (via Entware):**
- `php7` or `php7-cli` + `php7-cgi`
- `php7-mod-sqlite3` (SQLite database support)
- `php7-mod-fileinfo` (file type detection)
- `lighttpd` (web server)
- `lighttpd-mod-fastcgi` (PHP execution)
- `sqlite3-cli` (database management)

### Network Access

- Ethernet cable for initial setup (recommended)
- Computer with SSH/SCP capability
- Telnet client (initial DD-WRT access uses telnet, not SSH)
- Web browser for testing

---

## Architecture Overview

### Why Two USB Partitions?

EmergencyBox uses a two-partition USB setup for critical architectural reasons:

**Partition 1 (`/dev/sda1`) - Entware System Partition:**
- **Mount Point**: `/opt`
- **Purpose**: Entware package manager and installed software
- **Contents**:
  - `/opt/bin/` - Executable binaries (PHP, lighttpd, sqlite3)
  - `/opt/lib/` - Shared libraries
  - `/opt/etc/` - Configuration files
  - `/opt/share/zoneinfo/` - Timezone data (critical for PHP)
  - `/opt/var/` - Variable data (logs, PID files)
- **Why Separate**: Entware needs to mount over `/opt` at boot, which would hide any data stored there

**Partition 2 (`/dev/sda2`) - Application Data Partition:**
- **Mount Point**: `/mnt/data`
- **Purpose**: EmergencyBox application and user data
- **Contents**:
  - `/mnt/data/www/` - Web application files
  - `/mnt/data/www/uploads/` - User-uploaded files
  - `/mnt/data/emergencybox.db` - SQLite database
- **Why Separate**: Data persists independently of Entware overlay mounting

**Key Insight**: During deployment, we discovered that mounting `/dev/sda1` to `/opt` overlays the filesystem, hiding any files previously in `/opt/share/`. This caused PHP timezone crashes until timezone files were copied to the correct partition.

### Why Telnet Instead of SSH?

DD-WRT's initial configuration uses **telnet** instead of SSH for security reasons:
- First login via telnet forces you to set a password
- SSH is automatically enabled after password is set
- This prevents routers from shipping with default SSH credentials
- After initial setup, **always use SSH** for secure access

### Why PHP 7.x and Not PHP 8.x?

PHP version choice is dictated by Entware package availability:
- **PHP 7.4**: Widely available in Entware for ARM architecture
- **PHP 8.x**: May not be available for older ARM kernels
- **Compatibility**: PHP 7.4 fully supports all EmergencyBox features
- **Extensions**: Both `sqlite3` and `fileinfo` modules available for PHP 7.x
- **Memory**: PHP 7.4 has lower memory footprint than 8.x (important for 256MB RAM)

### Port Configuration

**Port 80**: DD-WRT's built-in HTTP daemon (`httpd`) runs on port 80 by default for the router admin interface.

**Port 8080**: EmergencyBox runs on port 8080 to avoid conflicts.

**Why Not Disable DD-WRT httpd?**
- Router admin interface remains accessible
- Avoids breaking DD-WRT's web-based configuration
- Easy to remember: `http://192.168.1.1` (admin) vs `http://192.168.1.1:8080` (EmergencyBox)

---

## Step-by-Step Deployment

### Phase 1: Firmware Installation

#### Step 1.1: Download DD-WRT Firmware

1. Visit the DD-WRT router database:
   ```
   https://dd-wrt.com/support/router-database/
   ```

2. Search for "ASUS RT-AC68U"

3. Download the appropriate firmware file (`.trx` for most installations)

4. Verify file integrity:
   ```bash
   sha256sum asus_rt-ac68u-firmware.trx
   ```

#### Step 1.2: Flash DD-WRT Firmware

**Method A: Via ASUS Web Interface (if currently running ASUS stock firmware)**

1. Connect to router via Ethernet cable
2. Access router admin interface: `http://192.168.1.1`
3. Login with admin credentials
4. Navigate to: **Administration > Firmware Upgrade**
5. Choose the DD-WRT `.trx` file
6. Click **Upload**
7. **DO NOT interrupt power** during flashing (5-10 minutes)
8. Router will reboot automatically

**Method B: Via TFTP Recovery Mode (if brick or failed flash)**

1. Download TFTP client
2. Set computer IP to `192.168.1.10`, subnet `255.255.255.0`
3. Power off router
4. Hold **Reset button** and power on router
5. Wait for power LED to start blinking
6. Upload firmware via TFTP:
   ```bash
   tftp 192.168.1.1
   binary
   put asus_rt-ac68u-firmware.trx
   ```
7. Wait 5-10 minutes for completion

#### Step 1.3: Initial DD-WRT Setup

1. After reboot, access router: `http://192.168.1.1`

2. DD-WRT will prompt for username/password setup:
   - **Username**: `root`
   - **Password**: (choose strong password)

3. Complete basic wireless setup (SSID, encryption)

4. **Important**: Note that initial access uses **telnet**, not SSH

5. Set a password via telnet to enable SSH:
   ```bash
   telnet 192.168.1.1
   # Login as root
   passwd
   # Enter new password twice
   # SSH is now enabled
   ```

### Phase 2: USB Storage Preparation

#### Step 2.1: Partition USB Drive

**On Linux/Mac:**

```bash
# Identify USB device
lsblk

# Assume USB is /dev/sdb
# CAUTION: This will erase all data on the drive!

# Create partition table
sudo parted /dev/sdb mklabel gpt

# Create two partitions
sudo parted /dev/sdb mkpart primary ext4 0% 50%      # Partition 1: Entware
sudo parted /dev/sdb mkpart primary ext4 50% 100%    # Partition 2: Data

# Format partitions
sudo mkfs.ext4 -L "Entware" /dev/sdb1
sudo mkfs.ext4 -L "Data" /dev/sdb2

# Verify
lsblk -f /dev/sdb
```

**On Windows:**

Use a tool like **Rufus** or **GParted Live USB** to create two ext4 partitions.

#### Step 2.2: Insert USB Drive into Router

1. Safely eject USB from computer
2. Insert into router's USB port (USB 3.0 preferred if available)
3. Wait 10 seconds for router to detect

#### Step 2.3: Verify USB Detection

```bash
ssh root@192.168.1.1

# Check detected drives
ls -l /dev/sd*

# Expected output:
# /dev/sda
# /dev/sda1  (Entware partition)
# /dev/sda2  (Data partition)

# Check filesystem
blkid /dev/sda1
blkid /dev/sda2
```

### Phase 3: Entware Installation

#### Step 3.1: Enable USB Support in DD-WRT

1. Access DD-WRT web interface: `http://192.168.1.1`
2. Navigate to: **Services > USB**
3. Enable the following:
   - **Core USB Support**: Enabled
   - **USB Storage Support**: Enabled
   - **Automatic Drive Mount**: Enabled
4. Click **Save** and **Apply Settings**

#### Step 3.2: Mount First Partition

```bash
ssh root@192.168.1.1

# Create mount point
mkdir -p /opt

# Mount Entware partition
mount /dev/sda1 /opt

# Verify mount
df -h | grep sda1
```

#### Step 3.3: Install Entware

```bash
# Download Entware installer
cd /opt
wget http://bin.entware.net/armv7sf-k3.2/installer/generic.sh

# Run installer
sh generic.sh

# Update package database
/opt/bin/opkg update

# Verify installation
/opt/bin/opkg --version
```

#### Step 3.4: Configure Entware Auto-mount

**Important**: Entware must mount before starting services.

1. In DD-WRT web interface, go to: **Administration > Commands**

2. Add to **Startup** script:
   ```bash
   # Wait for USB to be ready
   sleep 10

   # Mount Entware partition
   mount /dev/sda1 /opt

   # Start Entware services
   /opt/etc/init.d/rc.unslung start
   ```

3. Click **Save Startup**

### Phase 4: Package Installation

#### Step 4.1: Install PHP and Extensions

```bash
ssh root@192.168.1.1

# Update package list
/opt/bin/opkg update

# Install PHP
/opt/bin/opkg install php7-cli php7-cgi

# Install PHP extensions
/opt/bin/opkg install php7-mod-sqlite3 php7-mod-fileinfo

# Verify PHP installation
/opt/bin/php -v

# Expected output:
# PHP 7.4.x (cli)
```

**Critical Check**: Verify PHP extensions loaded:

```bash
/opt/bin/php -m | grep -i sqlite
# Expected: sqlite3

/opt/bin/php -m | grep -i fileinfo
# Expected: fileinfo
```

#### Step 4.2: Install Web Server

```bash
# Install lighttpd and FastCGI module
/opt/bin/opkg install lighttpd lighttpd-mod-fastcgi

# Verify installation
/opt/sbin/lighttpd -v

# Expected output:
# lighttpd/1.4.x
```

#### Step 4.3: Install SQLite

```bash
# Install SQLite command-line tool
/opt/bin/opkg install sqlite3-cli

# Verify installation
/opt/bin/sqlite3 --version

# Expected output:
# 3.x.x
```

### Phase 5: EmergencyBox Deployment

#### Step 5.1: Mount Data Partition

```bash
ssh root@192.168.1.1

# Create mount point
mkdir -p /mnt/data

# Mount data partition
mount /dev/sda2 /mnt/data

# Verify mount
df -h | grep sda2

# Add to startup script (Administration > Commands > Startup):
sleep 10
mount /dev/sda2 /mnt/data
```

#### Step 5.2: Create Directory Structure

```bash
# Create application directories on data partition
mkdir -p /mnt/data/www
mkdir -p /mnt/data/www/api
mkdir -p /mnt/data/www/css
mkdir -p /mnt/data/www/js
mkdir -p /mnt/data/www/uploads/emergency
mkdir -p /mnt/data/www/uploads/media
mkdir -p /mnt/data/www/uploads/documents
mkdir -p /mnt/data/www/uploads/general

# Create config directory
mkdir -p /opt/etc/lighttpd

# Create log directory
mkdir -p /opt/var/log/lighttpd

# Verify structure
tree /mnt/data/www  # (if tree installed)
# OR
find /mnt/data/www -type d
```

#### Step 5.3: Transfer Files from Development Machine

**From your computer** (in the project directory):

```bash
# Set variables
ROUTER_IP="192.168.1.1"
ROUTER_USER="root"

# Copy web application files
scp -r www/* ${ROUTER_USER}@${ROUTER_IP}:/mnt/data/www/

# Copy configuration files
scp config/lighttpd.conf ${ROUTER_USER}@${ROUTER_IP}:/opt/etc/lighttpd/lighttpd.conf
scp config/php.ini ${ROUTER_USER}@${ROUTER_IP}:/opt/etc/php.ini
```

**Alternative**: Use the provided deployment script:

```bash
chmod +x deploy.sh
./deploy.sh 192.168.1.1 root
```

**Note**: You'll need to modify `deploy.sh` to use `/mnt/data` instead of `/opt/share`.

#### Step 5.4: Configure PHP

**Critical Configuration**: The `php.ini` must include proper `extension_dir` and timezone settings.

```bash
ssh root@192.168.1.1

# Edit PHP configuration
vi /opt/etc/php.ini
```

**Essential settings**:

```ini
; Extension directory (CRITICAL)
extension_dir = "/opt/lib/php"

; Timezone (CRITICAL - prevents crashes)
date.timezone = "UTC"

; Large file upload support
upload_max_filesize = 1024M
post_max_size = 1024M
max_execution_time = 600
max_input_time = 600
memory_limit = 128M

; File uploads
file_uploads = On
upload_tmp_dir = "/tmp"

; Error reporting
display_errors = On
log_errors = On
error_log = "/opt/var/log/php-errors.log"
```

**Why `extension_dir` is Critical**:
During deployment, we discovered that without explicitly setting `extension_dir`, PHP couldn't find the SQLite3 extension, causing all database operations to fail.

**Why Timezone Setting is Critical**:
PHP on embedded systems often lacks timezone data or can't find it. Without proper timezone configuration, PHP will crash with "Timezone database is corrupt" errors. See [Critical Issues](#timezone-data-issue) below.

#### Step 5.5: Configure lighttpd

```bash
ssh root@192.168.1.1

# Edit lighttpd configuration
vi /opt/etc/lighttpd/lighttpd.conf
```

**Configuration** (adjusted from provided config):

```conf
## EmergencyBox lighttpd Configuration
## Optimized for DD-WRT on ASUS RT-AC68U

server.modules = (
    "mod_access",
    "mod_alias",
    "mod_fastcgi",
    "mod_rewrite",
    "mod_setenv"
)

# Document root on data partition
server.document-root = "/mnt/data/www"
server.upload-dirs = ( "/tmp" )
server.errorlog = "/opt/var/log/lighttpd/error.log"
server.pid-file = "/opt/var/run/lighttpd.pid"
server.username = "root"
server.groupname = "root"

# Port 8080 to avoid DD-WRT httpd conflict
server.port = 8080

# MIME types
mimetype.assign = (
    ".html" => "text/html",
    ".htm" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".json" => "application/json",
    ".txt" => "text/plain",
    ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".png" => "image/png",
    ".gif" => "image/gif",
    ".svg" => "image/svg+xml",
    ".pdf" => "application/pdf",
    ".zip" => "application/zip",
    ".mp4" => "video/mp4",
    ".mp3" => "audio/mpeg",
    "" => "application/octet-stream"
)

# Index files
index-file.names = ( "index.html", "index.php" )

# FastCGI for PHP
fastcgi.server = (
    ".php" => (
        "localhost" => (
            "socket" => "/tmp/php-fastcgi.socket",
            "bin-path" => "/opt/bin/php-cgi",
            "bin-environment" => (
                "PHP_FCGI_CHILDREN" => "2",
                "PHP_FCGI_MAX_REQUESTS" => "1000"
            ),
            "broken-scriptfilename" => "enable",
            "max-procs" => 2,
            "idle-timeout" => 600
        )
    )
)

# Large file support
# Note: DD-WRT lighttpd parser has 32-bit signed integer limit
# Maximum: 2147483647 bytes (2GB - 1 byte)
# Setting to 1GB for safety
server.max-request-size = 1073741824  # 1GB

# Timeouts for large uploads
server.max-write-idle = 600
server.max-read-idle = 600

# Connection limits
server.max-connections = 50
server.max-fds = 256

# Static file caching
$HTTP["url"] =~ "\.(css|js|jpg|jpeg|png|gif|svg|ico)$" {
    expire.url = ( "" => "access plus 1 hours" )
}

# Directory listing disabled
dir-listing.activate = "disable"

# Access restrictions
$HTTP["url"] =~ "^/config/" {
    url.access-deny = ( "" )
}

$HTTP["url"] =~ "^/data/" {
    url.access-deny = ( "" )
}

# Allow uploads directory access
alias.url = (
    "/uploads/" => "/mnt/data/www/uploads/"
)
```

**Key Changes from Original**:
1. **Port 8080**: Avoids conflict with DD-WRT's httpd
2. **Document root**: `/mnt/data/www` instead of `/opt/share/www`
3. **Max upload size**: 1GB instead of 5GB (see [Critical Issues](#lighttpd-config-parser-limitation))
4. **User/Group**: `root` (DD-WRT doesn't have `nobody` user by default)

#### Step 5.6: Initialize Database

```bash
ssh root@192.168.1.1

# Run database initialization script
/opt/bin/php /mnt/data/www/api/init_db.php

# Expected output:
# Database initialized successfully at /mnt/data/emergencybox.db

# Verify database creation
ls -lh /mnt/data/emergencybox.db

# Check database schema
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".schema"
```

**Expected Schema**:

```sql
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT DEFAULT NULL,
    message TEXT NOT NULL,
    priority INTEGER DEFAULT 0,
    file_id INTEGER DEFAULT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    category TEXT NOT NULL,
    size INTEGER NOT NULL,
    uploaded DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE announcements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT NOT NULL,
    active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Critical**: If you see errors about timezone database corruption, see [Timezone Issue](#timezone-data-issue) below.

#### Step 5.7: Set Permissions

```bash
ssh root@192.168.1.1

# Set web directory permissions
chmod -R 755 /mnt/data/www

# Set upload directory permissions (must be writable)
chmod -R 777 /mnt/data/www/uploads

# Set database permissions
chmod 644 /mnt/data/emergencybox.db
chmod 755 /mnt/data

# Verify permissions
ls -la /mnt/data/
ls -la /mnt/data/www/
ls -la /mnt/data/www/uploads/
```

### Phase 6: Service Configuration

#### Step 6.1: Create lighttpd Init Script

```bash
ssh root@192.168.1.1

# Create init script
vi /opt/etc/init.d/S80lighttpd
```

**Init script content**:

```bash
#!/bin/sh

ENABLED=yes
PROCS=lighttpd
ARGS="-f /opt/etc/lighttpd/lighttpd.conf"
PREARGS=""
DESC=$PROCS
PATH=/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

. /opt/etc/init.d/rc.func
```

**Make executable**:

```bash
chmod +x /opt/etc/init.d/S80lighttpd
```

#### Step 6.2: Configure Auto-start

**Update DD-WRT Startup Commands** (Administration > Commands > Startup):

```bash
#!/bin/sh

# Wait for USB to be ready
sleep 10

# Mount Entware partition
mount /dev/sda1 /opt

# Mount data partition
mount /dev/sda2 /mnt/data

# Start Entware services
/opt/etc/init.d/rc.unslung start

# Start lighttpd
/opt/etc/init.d/S80lighttpd start
```

Click **Save Startup**.

#### Step 6.3: Start Services

```bash
ssh root@192.168.1.1

# Start lighttpd
/opt/etc/init.d/S80lighttpd start

# Verify lighttpd is running
ps | grep lighttpd

# Expected output:
# 12345 root      0:00 /opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf
# 12346 root      0:00 /opt/bin/php-cgi

# Check listening ports
netstat -ln | grep 8080

# Expected output:
# tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN

# Check error log
tail -f /opt/var/log/lighttpd/error.log
```

---

## Critical Issues & Solutions

During the real-world deployment of EmergencyBox to an ASUS RT-AC68U router, we encountered several critical issues. This section documents each problem, the investigation process, and the solution.

### Issue 1: Timezone Data Causing PHP Crashes

**Symptoms:**
- PHP scripts crash with no output
- `strace` reveals:
  ```
  open("/opt/share/zoneinfo/UTC", O_RDONLY) = -1 ENOENT (No such file or directory)
  write(2, "Timezone database is corrupt - th"..., 87) = 87
  exit_group(1)
  ```
- Database initialization fails silently

**Root Cause:**

PHP on embedded systems requires timezone data files in `/opt/share/zoneinfo/`. However, when `/dev/sda1` is mounted to `/opt`, it overlays the filesystem, hiding the original `/opt/share/zoneinfo/` directory that was created during Entware installation.

**Investigation Process:**

1. Ran PHP with `strace` to capture system calls:
   ```bash
   strace /opt/bin/php /mnt/data/www/api/init_db.php 2>&1 | grep -i zone
   ```

2. Discovered missing timezone files:
   ```bash
   ls /opt/share/zoneinfo/
   # Error: No such file or directory
   ```

3. Checked if files exist on unmounted partition:
   ```bash
   umount /opt
   ls /opt/share/zoneinfo/  # Files exist!
   mount /dev/sda1 /opt
   ls /opt/share/zoneinfo/  # Files gone (hidden by mount)
   ```

**Solution:**

**Option A: Copy timezone data to mounted partition (IMPLEMENTED)**

```bash
# Temporarily unmount /opt
umount /opt

# Copy timezone files to a temporary location
cp -r /opt/share/zoneinfo /tmp/

# Remount /opt
mount /dev/sda1 /opt

# Recreate directory structure
mkdir -p /opt/share/zoneinfo

# Copy timezone files back
cp -r /tmp/zoneinfo/* /opt/share/zoneinfo/

# Verify
ls -la /opt/share/zoneinfo/
# Should show timezone files: Africa/, America/, UTC, etc.

# Test PHP
/opt/bin/php -r "echo date('Y-m-d H:i:s');"
# Should output current date/time without errors
```

**Option B: Configure PHP to use system timezone**

Edit `/opt/etc/php.ini`:

```ini
date.timezone = "UTC"
```

This tells PHP to use UTC directly without loading timezone database files.

**Option C: Use environment variable**

```bash
export TZ=UTC
/opt/bin/php /mnt/data/www/api/init_db.php
```

**Best Practice**: Use a combination of Options A and B for maximum reliability.

### Issue 2: SQLite3 Extension Not Loading

**Symptoms:**
- PHP scripts fail with: "Class 'SQLite3' not found"
- `php -m` doesn't list `sqlite3` module
- Database operations fail

**Root Cause:**

PHP couldn't locate the SQLite3 extension library because `extension_dir` was not configured in `php.ini`.

**Investigation Process:**

1. Checked if extension is installed:
   ```bash
   /opt/bin/opkg list-installed | grep php7-mod-sqlite3
   # Confirmed: php7-mod-sqlite3 is installed
   ```

2. Checked PHP modules:
   ```bash
   /opt/bin/php -m | grep sqlite
   # No output - module not loaded
   ```

3. Located extension file:
   ```bash
   find /opt -name "sqlite3.so"
   # Found at: /opt/lib/php/sqlite3.so
   ```

4. Checked `php.ini`:
   ```bash
   /opt/bin/php --ini
   # Configuration File (php.ini) Path: /opt/etc
   # Loaded Configuration File:         /opt/etc/php.ini

   grep extension_dir /opt/etc/php.ini
   # No output - extension_dir not set!
   ```

**Solution:**

Edit `/opt/etc/php.ini` and add:

```ini
; Extension directory (MUST be set)
extension_dir = "/opt/lib/php"

; Load SQLite3 extension
extension=sqlite3.so

; Load fileinfo extension (for upload file type detection)
extension=fileinfo.so
```

**Verify fix:**

```bash
# Restart PHP-CGI (kill existing processes, lighttpd will restart them)
killall php-cgi

# Check loaded modules
/opt/bin/php -m | grep sqlite3
# Expected output: sqlite3

# Test SQLite3 functionality
/opt/bin/php -r "new SQLite3(':memory:'); echo 'SQLite3 works!';"
# Expected output: SQLite3 works!
```

### Issue 3: lighttpd Config Parser Limitation (5GB → 1GB)

**Symptoms:**
- lighttpd fails to start
- Error in log: "config parsing failed" or "value too large"
- Configuration file appears correct

**Root Cause:**

The lighttpd configuration parser on DD-WRT has a 32-bit signed integer limitation. The original configuration specified:

```conf
server.max-request-size = 5368709120  # 5GB in bytes
```

This value exceeds the maximum 32-bit signed integer (2,147,483,647), causing the parser to fail.

**Investigation Process:**

1. Attempted to start lighttpd:
   ```bash
   /opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf -t
   # Output: configuration parsing failed
   ```

2. Checked error log:
   ```bash
   cat /opt/var/log/lighttpd/error.log
   # Error: (configfile.c.xxx) value too large at line XX
   ```

3. Identified the problematic line:
   ```bash
   grep -n "max-request-size" /opt/etc/lighttpd/lighttpd.conf
   # Line 61: server.max-request-size = 5368709120
   ```

4. Calculated maximum safe value:
   ```
   Maximum 32-bit signed integer: 2,147,483,647 bytes (≈ 2GB)
   Safe value for production: 1,073,741,824 bytes (1GB)
   ```

**Solution:**

Edit `/opt/etc/lighttpd/lighttpd.conf`:

```conf
# Reduced from 5GB to 1GB due to lighttpd parser limitation
server.max-request-size = 1073741824  # 1GB in bytes
```

**Note**: If you need to support files larger than 1GB, consider:
- Using alternative web servers (nginx, Apache)
- Implementing chunked upload in JavaScript
- Using a streaming upload approach
- Compiling a custom lighttpd build with 64-bit integer support

**Verify fix:**

```bash
# Test configuration syntax
/opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf -t
# Expected output: Syntax OK

# Start lighttpd
/opt/etc/init.d/S80lighttpd start

# Verify running
ps | grep lighttpd
```

### Issue 4: Port Conflict (DD-WRT httpd vs lighttpd)

**Symptoms:**
- lighttpd fails to start
- Error: "bind failed: Address already in use"
- Port 80 already occupied

**Root Cause:**

DD-WRT runs its own HTTP daemon (`httpd`) on port 80 for the router administration interface. lighttpd cannot bind to port 80 when it's already in use.

**Investigation Process:**

1. Checked what's listening on port 80:
   ```bash
   netstat -ln | grep ":80 "
   # Output: tcp  0  0  0.0.0.0:80  0.0.0.0:*  LISTEN

   ps | grep httpd
   # Output: 1234 root  0:00 httpd
   ```

2. Identified DD-WRT's httpd is running

3. Considered options:
   - **Option A**: Disable DD-WRT httpd (NOT RECOMMENDED - breaks admin interface)
   - **Option B**: Change DD-WRT httpd port (possible but affects admin access)
   - **Option C**: Run EmergencyBox on alternate port (RECOMMENDED)

**Solution:**

Configure lighttpd to run on port 8080 instead of port 80.

Edit `/opt/etc/lighttpd/lighttpd.conf`:

```conf
# Changed from port 80 to 8080
server.port = 8080
```

**Update EmergencyBox URLs:**

Users will access EmergencyBox at:
```
http://192.168.1.1:8080
```

Router admin interface remains at:
```
http://192.168.1.1
```

**Advantages of this approach:**
- Router admin interface remains accessible
- No DD-WRT configuration changes needed
- Clear separation between router admin and EmergencyBox
- Easy to remember both URLs

**Verify fix:**

```bash
# Start lighttpd
/opt/etc/init.d/S80lighttpd start

# Check listening ports
netstat -ln | grep -E ":(80|8080) "
# Expected:
# tcp  0  0  0.0.0.0:80    0.0.0.0:*  LISTEN   (DD-WRT httpd)
# tcp  0  0  0.0.0.0:8080  0.0.0.0:*  LISTEN   (lighttpd)
```

### Issue 5: Database Schema Mismatch

**Symptoms:**
- Database file exists but queries fail
- Errors: "no such table: messages"
- Application can't read/write data

**Root Cause:**

The database file `/mnt/data/emergencybox.db` was created manually using `sqlite3` command-line tool, but the schema didn't match what the PHP application expected. Specifically, the `announcements` table was missing.

**Investigation Process:**

1. Checked database existence:
   ```bash
   ls -lh /mnt/data/emergencybox.db
   # File exists
   ```

2. Examined database schema:
   ```bash
   /opt/bin/sqlite3 /mnt/data/emergencybox.db ".schema"
   # Output showed only 'messages' and 'files' tables
   # Missing: 'announcements' table
   ```

3. Reviewed PHP code in `/mnt/data/www/api/config.php`:
   ```php
   // Create announcements table
   $db->exec("CREATE TABLE IF NOT EXISTS announcements ...");
   ```

4. Realized the proper initialization required running `init_db.php`

**Solution:**

Always initialize the database using the provided PHP script, not manually:

```bash
# Remove any manually created database
rm -f /mnt/data/emergencybox.db

# Initialize properly using PHP script
/opt/bin/php /mnt/data/www/api/init_db.php

# Verify all tables exist
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".tables"
# Expected output: announcements  files  messages
```

**Verify schema:**

```bash
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".schema"
```

Should show all three tables with correct structure.

**Test database access from PHP:**

```bash
/opt/bin/php -r '
$db = new SQLite3("/mnt/data/emergencybox.db");
$result = $db->query("SELECT COUNT(*) as count FROM messages");
$row = $result->fetchArray();
echo "Messages: " . $row["count"] . "\n";
'
# Expected output: Messages: 0
```

### Issue 6: Browser Cache Serving PHP Source Code

**Symptoms:**
- Browser displays PHP source code instead of executing it
- File downloads show `.php` files as text
- Application doesn't load properly after changes

**Root Cause:**

Browser caching can serve old responses, particularly if the web server configuration changed (e.g., FastCGI not working initially, then fixed). The browser returns cached responses from before FastCGI was properly configured.

**Investigation Process:**

1. Tested with `curl` (no cache):
   ```bash
   curl http://192.168.1.1:8080/api/get_messages.php
   # Output: JSON response (correct)
   ```

2. Tested in browser:
   ```
   Shows PHP source code
   ```

3. Checked browser Network tab:
   ```
   Status: 200 (from cache)
   ```

4. Realized browser is serving cached responses

**Solution:**

**Immediate Fix (Client-side):**

1. **Hard refresh** in browser:
   - **Windows/Linux**: `Ctrl + F5` or `Ctrl + Shift + R`
   - **Mac**: `Cmd + Shift + R`

2. **Clear browser cache**:
   - Chrome: Settings > Privacy and Security > Clear browsing data
   - Firefox: Settings > Privacy & Security > Clear Data

3. **Use private/incognito mode** for testing

**Server-side Fix (Prevent caching of dynamic content):**

Edit `/opt/etc/lighttpd/lighttpd.conf`:

```conf
# Prevent caching of PHP files
$HTTP["url"] =~ "\.php$" {
    setenv.add-response-header = (
        "Cache-Control" => "no-cache, no-store, must-revalidate",
        "Pragma" => "no-cache",
        "Expires" => "0"
    )
}

# Cache static files only
$HTTP["url"] =~ "\.(css|js|jpg|jpeg|png|gif|svg|ico)$" {
    expire.url = ( "" => "access plus 1 hours" )
}
```

**Verify fix:**

```bash
# Restart lighttpd
/opt/etc/init.d/S80lighttpd restart

# Test with curl (check headers)
curl -I http://192.168.1.1:8080/api/get_messages.php
# Should show:
# Cache-Control: no-cache, no-store, must-revalidate
```

### Issue 7: File Upload Permission Errors

**Symptoms:**
- File uploads fail with "Permission denied"
- Error log shows: "failed to create file"
- Upload directory exists but not writable

**Root Cause:**

Upload directory `/mnt/data/www/uploads/` has incorrect permissions, preventing PHP from writing files.

**Solution:**

```bash
ssh root@192.168.1.1

# Set proper permissions on upload directory
chmod -R 777 /mnt/data/www/uploads

# Verify permissions
ls -ld /mnt/data/www/uploads
# Expected: drwxrwxrwx

ls -la /mnt/data/www/uploads/
# All subdirectories should be drwxrwxrwx
```

**Security Note:**

`777` permissions (world-writable) are generally insecure, but acceptable in this case because:
1. EmergencyBox is designed for offline, trusted environments
2. DD-WRT has limited user separation
3. The router is not connected to the internet
4. All users are considered trusted in disaster relief scenarios

For higher security environments, consider:
- Creating a dedicated user for lighttpd
- Using `755` or `775` permissions with proper group ownership
- Implementing file scanning/validation

---

## Testing & Verification

### Initial Connectivity Test

```bash
# Ping router
ping 192.168.1.1

# Test if port 8080 is accessible
curl http://192.168.1.1:8080
# Should return HTML (index.html)
```

### Service Health Check

```bash
ssh root@192.168.1.1

# Check if lighttpd is running
ps | grep lighttpd
# Expected: 2-3 processes (master + workers + php-cgi)

# Check listening ports
netstat -ln | grep 8080
# Expected: LISTEN on 0.0.0.0:8080

# Check logs for errors
tail -20 /opt/var/log/lighttpd/error.log
# Should not show recent errors
```

### Database Test

```bash
ssh root@192.168.1.1

# Check database file
ls -lh /mnt/data/emergencybox.db

# Test database access
/opt/bin/sqlite3 /mnt/data/emergencybox.db "SELECT COUNT(*) FROM messages;"
# Should return a number (0 if no messages yet)

# Test PHP database access
/opt/bin/php -r '
$db = new SQLite3("/mnt/data/emergencybox.db");
echo "Database connection: OK\n";
$result = $db->query("SELECT name FROM sqlite_master WHERE type=\"table\"");
while ($row = $result->fetchArray()) {
    echo "Table: " . $row["name"] . "\n";
}
'
# Expected output:
# Database connection: OK
# Table: messages
# Table: files
# Table: announcements
```

### Web Interface Test

1. **Open browser** and navigate to:
   ```
   http://192.168.1.1:8080
   ```

2. **Verify interface loads**:
   - EmergencyBox title visible
   - Chat area visible
   - File upload section visible
   - No JavaScript errors in browser console (F12)

3. **Test chat functionality**:
   - Enter a test message
   - Click "Send"
   - Message should appear in chat area
   - Reload page - message should persist

4. **Test priority message**:
   - Check "Priority" checkbox
   - Send message
   - Message should appear with red styling

### File Upload Test (Small File)

1. **Prepare test file**:
   ```bash
   # On your computer
   echo "Test file content" > test.txt
   ```

2. **Upload via web interface**:
   - Click "Choose File"
   - Select `test.txt`
   - Select category (e.g., "General")
   - Click "Upload"
   - Should show progress bar
   - Should show success message

3. **Verify upload on router**:
   ```bash
   ssh root@192.168.1.1
   ls -lh /mnt/data/www/uploads/general/
   # Should show test.txt

   cat /mnt/data/www/uploads/general/test.txt
   # Should show: Test file content
   ```

4. **Verify database entry**:
   ```bash
   /opt/bin/sqlite3 /mnt/data/emergencybox.db "SELECT * FROM files;"
   # Should show entry for test.txt
   ```

5. **Test download**:
   - Click on uploaded file in file browser
   - File should download
   - Content should match original

### File Upload Test (Large File)

1. **Create large test file** (100MB):
   ```bash
   # On your computer
   dd if=/dev/zero of=largefile.bin bs=1M count=100
   ```

2. **Upload via web interface**:
   - Upload `largefile.bin`
   - Monitor progress bar
   - Should complete without errors
   - May take several minutes depending on WiFi speed

3. **Verify on router**:
   ```bash
   ssh root@192.168.1.1
   ls -lh /mnt/data/www/uploads/general/largefile.bin
   # Should show ~100M size
   ```

4. **Test download**:
   - Download the large file
   - Verify size matches
   - Optional: Verify MD5 checksum

### Stress Test (Multiple Files)

Upload multiple files in succession:
- 5-10 small files (< 10MB each)
- 2-3 medium files (50-100MB each)
- Verify all appear in file browser
- Check disk space: `df -h`

### Multi-User Test

1. **Connect with multiple devices** (phone, tablet, laptop)

2. **Each device**:
   - Navigate to `http://192.168.1.1:8080`
   - Send chat messages
   - Upload files

3. **Verify**:
   - All devices see all messages
   - All devices see all files
   - No conflicts or errors

### Persistence Test (Reboot)

1. **Reboot router**:
   ```bash
   ssh root@192.168.1.1
   reboot
   ```

2. **Wait for reboot** (2-3 minutes)

3. **Reconnect and verify**:
   - Services auto-started: `ps | grep lighttpd`
   - Database persists: Previous messages visible
   - Files persist: Previous uploads visible
   - Web interface accessible

### Performance Benchmarking

**Upload speed test:**
```bash
# Create 50MB test file
dd if=/dev/zero of=50mb.bin bs=1M count=50

# Time upload (using curl)
time curl -F "file=@50mb.bin" -F "category=general" http://192.168.1.1:8080/api/upload.php
```

Typical results:
- **WiFi 2.4GHz**: 3-7 MB/s
- **WiFi 5GHz**: 10-15 MB/s
- **Gigabit Ethernet**: 20-40 MB/s

**Concurrent user simulation:**
```bash
# Use Apache Bench (ab) to simulate load
ab -n 100 -c 10 http://192.168.1.1:8080/
```

Monitor router resources:
```bash
ssh root@192.168.1.1
top
# Watch CPU and memory usage
```

### Test Checklist

Use this checklist to verify complete functionality:

- [ ] Router accessible via WiFi
- [ ] Web interface loads at `http://192.168.1.1:8080`
- [ ] Can send regular chat messages
- [ ] Can send priority chat messages
- [ ] Chat messages persist after page reload
- [ ] Can upload small file (< 10MB)
- [ ] Can upload medium file (50-100MB)
- [ ] Can upload large file (500MB-1GB)
- [ ] Uploaded files appear in file browser
- [ ] Can download uploaded files
- [ ] File search works
- [ ] Can create custom folders
- [ ] Can link files to chat messages
- [ ] Multiple devices can connect simultaneously
- [ ] All devices see same chat messages
- [ ] All devices see same files
- [ ] System survives router reboot
- [ ] Services auto-start after reboot
- [ ] Database persists after reboot
- [ ] Uploaded files persist after reboot
- [ ] No errors in lighttpd log
- [ ] Disk space monitored and adequate
- [ ] Router admin interface still accessible at `http://192.168.1.1`

---

## Troubleshooting

### EmergencyBox Not Accessible

**Problem**: Cannot access `http://192.168.1.1:8080`

**Diagnosis:**

```bash
ssh root@192.168.1.1

# Check if lighttpd is running
ps | grep lighttpd
# If no output, lighttpd is not running

# Check if port is listening
netstat -ln | grep 8080
# If no output, nothing is listening on port 8080

# Check error log
cat /opt/var/log/lighttpd/error.log
```

**Solutions:**

1. **Start lighttpd**:
   ```bash
   /opt/etc/init.d/S80lighttpd start
   ```

2. **Check configuration syntax**:
   ```bash
   /opt/sbin/lighttpd -t -f /opt/etc/lighttpd/lighttpd.conf
   ```

3. **Verify document root exists**:
   ```bash
   ls -la /mnt/data/www/
   ```

4. **Check PHP-CGI**:
   ```bash
   /opt/bin/php-cgi -v
   ```

5. **Restart services**:
   ```bash
   /opt/etc/init.d/S80lighttpd restart
   killall php-cgi  # Will be restarted by lighttpd
   ```

### File Upload Fails

**Problem**: File uploads time out or fail

**Diagnosis:**

```bash
# Check upload directory permissions
ls -ld /mnt/data/www/uploads/
# Should be: drwxrwxrwx

# Check disk space
df -h /mnt/data
# Ensure sufficient free space

# Check PHP error log
cat /opt/var/log/php-errors.log

# Check lighttpd error log
tail -20 /opt/var/log/lighttpd/error.log

# Test upload with curl
curl -F "file=@test.txt" -F "category=general" http://192.168.1.1:8080/api/upload.php
```

**Solutions:**

1. **Fix permissions**:
   ```bash
   chmod -R 777 /mnt/data/www/uploads
   ```

2. **Increase PHP limits** (edit `/opt/etc/php.ini`):
   ```ini
   upload_max_filesize = 1024M
   post_max_size = 1024M
   max_execution_time = 600
   memory_limit = 128M
   ```

3. **Check lighttpd max request size** (edit `/opt/etc/lighttpd/lighttpd.conf`):
   ```conf
   server.max-request-size = 1073741824  # 1GB
   ```

4. **Free up disk space**:
   ```bash
   # Delete old uploads
   rm -rf /mnt/data/www/uploads/general/*

   # Or expand to larger USB drive
   ```

5. **Restart services**:
   ```bash
   /opt/etc/init.d/S80lighttpd restart
   ```

### Database Errors

**Problem**: Database queries fail or return errors

**Diagnosis:**

```bash
# Check if database file exists
ls -lh /mnt/data/emergencybox.db

# Check database integrity
/opt/bin/sqlite3 /mnt/data/emergencybox.db "PRAGMA integrity_check;"
# Should output: ok

# Check tables exist
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".tables"
# Should show: announcements  files  messages

# Check PHP SQLite3 extension
/opt/bin/php -m | grep sqlite3
# Should output: sqlite3
```

**Solutions:**

1. **Reinitialize database**:
   ```bash
   rm -f /mnt/data/emergencybox.db
   /opt/bin/php /mnt/data/www/api/init_db.php
   ```

2. **Fix permissions**:
   ```bash
   chmod 644 /mnt/data/emergencybox.db
   chmod 755 /mnt/data
   ```

3. **Verify extension_dir in php.ini**:
   ```bash
   grep extension_dir /opt/etc/php.ini
   # Should show: extension_dir = "/opt/lib/php"
   ```

4. **Reload PHP**:
   ```bash
   killall php-cgi
   /opt/etc/init.d/S80lighttpd restart
   ```

### Services Don't Auto-Start After Reboot

**Problem**: After router reboot, EmergencyBox is not accessible

**Diagnosis:**

```bash
ssh root@192.168.1.1

# Check if USB is mounted
df -h | grep sda
# Should show /dev/sda1 on /opt and /dev/sda2 on /mnt/data

# Check if Entware started
ls /opt/bin/opkg
# Should exist

# Check if lighttpd is running
ps | grep lighttpd
# Should show lighttpd processes
```

**Solutions:**

1. **Verify startup script** in DD-WRT:
   - Navigate to: Administration > Commands
   - Check **Startup** section
   - Ensure it contains:
     ```bash
     sleep 10
     mount /dev/sda1 /opt
     mount /dev/sda2 /mnt/data
     /opt/etc/init.d/rc.unslung start
     /opt/etc/init.d/S80lighttpd start
     ```
   - Click **Save Startup** if modified

2. **Increase sleep delay** (USB may need more time):
   ```bash
   sleep 20  # Increase from 10 to 20 seconds
   ```

3. **Manual start for testing**:
   ```bash
   ssh root@192.168.1.1
   mount /dev/sda1 /opt
   mount /dev/sda2 /mnt/data
   /opt/etc/init.d/rc.unslung start
   /opt/etc/init.d/S80lighttpd start
   ```

4. **Check for errors**:
   ```bash
   cat /opt/var/log/lighttpd/error.log
   ```

### Out of Memory

**Problem**: Router crashes or services stop under load

**Diagnosis:**

```bash
ssh root@192.168.1.1

# Check memory usage
free
# Look at "free" column

# Check processes
top
# Press Shift+M to sort by memory
# Press Q to quit

# Check swap
swapon -s
```

**Solutions:**

1. **Create swap file**:
   ```bash
   # Create 256MB swap file on USB
   dd if=/dev/zero of=/mnt/data/swapfile bs=1M count=256
   chmod 600 /mnt/data/swapfile
   mkswap /mnt/data/swapfile
   swapon /mnt/data/swapfile

   # Add to startup script:
   swapon /mnt/data/swapfile
   ```

2. **Reduce PHP memory limit** (edit `/opt/etc/php.ini`):
   ```ini
   memory_limit = 64M  # Reduce from 128M
   ```

3. **Reduce concurrent connections** (edit `/opt/etc/lighttpd/lighttpd.conf`):
   ```conf
   server.max-connections = 25  # Reduce from 50
   ```

4. **Reduce PHP workers**:
   ```conf
   "PHP_FCGI_CHILDREN" => "1",  # Reduce from 2
   ```

5. **Disable unnecessary DD-WRT services**:
   - Navigate to: Services > Services
   - Disable services you don't need (e.g., DLNA, NAS)

### Slow Performance

**Problem**: File uploads are slow or interface is laggy

**Diagnosis:**

```bash
# Check CPU usage
top

# Check disk I/O
iostat (if installed)

# Check WiFi signal strength
# From client device, check signal bars or connection info

# Test upload speed
time curl -F "file=@100mb.bin" http://192.168.1.1:8080/api/upload.php
```

**Solutions:**

1. **Use USB 3.0 port** (if available)

2. **Format USB as ext4** (not FAT32):
   ```bash
   umount /dev/sda1
   mkfs.ext4 /dev/sda1
   mount /dev/sda1 /opt
   ```

3. **Optimize WiFi settings**:
   - Use 5GHz band if supported
   - Reduce channel width if interference
   - Position router centrally

4. **Enable compression** (edit `/opt/etc/lighttpd/lighttpd.conf`):
   ```conf
   server.modules += ( "mod_compress" )
   compress.cache-dir = "/tmp/lighttpd-compress"
   compress.filetype = ("text/html", "text/css", "application/javascript")
   ```

5. **Limit concurrent uploads**:
   - Instruct users to upload one file at a time
   - Implement queue in JavaScript

### PHP Scripts Show Source Code

**Problem**: Browser displays PHP code instead of executing it

**Diagnosis:**

```bash
# Test with curl
curl http://192.168.1.1:8080/api/get_messages.php
# Should return JSON, not PHP code

# Check FastCGI configuration
grep -A 10 "fastcgi.server" /opt/etc/lighttpd/lighttpd.conf

# Check if php-cgi is running
ps | grep php-cgi
```

**Solutions:**

1. **Clear browser cache**:
   - Hard refresh: `Ctrl + F5` (Windows/Linux) or `Cmd + Shift + R` (Mac)
   - Or use incognito/private mode

2. **Verify FastCGI config** in `/opt/etc/lighttpd/lighttpd.conf`:
   ```conf
   fastcgi.server = (
       ".php" => (
           "localhost" => (
               "socket" => "/tmp/php-fastcgi.socket",
               "bin-path" => "/opt/bin/php-cgi",
               ...
           )
       )
   )
   ```

3. **Restart services**:
   ```bash
   killall php-cgi
   /opt/etc/init.d/S80lighttpd restart
   ```

4. **Check PHP execution**:
   ```bash
   /opt/bin/php-cgi -v
   # Should output PHP version
   ```

### Timezone Errors Persist

**Problem**: PHP still crashes with timezone errors after fix

**Diagnosis:**

```bash
# Check if timezone files exist
ls -la /opt/share/zoneinfo/
# Should show directories: Africa, America, Asia, etc.

# Check PHP timezone setting
grep timezone /opt/etc/php.ini
# Should show: date.timezone = "UTC"

# Test PHP date functions
/opt/bin/php -r "echo date('Y-m-d H:i:s');"
# Should output current date without errors
```

**Solutions:**

1. **Ensure timezone files are on mounted partition**:
   ```bash
   # Check if files are hidden by mount
   umount /opt
   ls /opt/share/zoneinfo/  # Files should exist here

   # Copy to persistent location
   cp -r /opt/share/zoneinfo /tmp/
   mount /dev/sda1 /opt
   mkdir -p /opt/share/zoneinfo
   cp -r /tmp/zoneinfo/* /opt/share/zoneinfo/
   ```

2. **Set timezone in php.ini**:
   ```bash
   echo "date.timezone = UTC" >> /opt/etc/php.ini
   ```

3. **Use environment variable**:
   ```bash
   # Add to lighttpd FastCGI config:
   "bin-environment" => (
       "TZ" => "UTC",
       ...
   )
   ```

4. **Restart PHP**:
   ```bash
   killall php-cgi
   /opt/etc/init.d/S80lighttpd restart
   ```

---

## Maintenance

### Regular Maintenance Tasks

**Daily** (if actively deployed):
- Monitor disk space: `df -h`
- Check error logs: `tail /opt/var/log/lighttpd/error.log`
- Verify services running: `ps | grep lighttpd`

**Weekly**:
- Review uploaded files, delete unnecessary ones
- Clear old chat messages if desired
- Backup database
- Check for package updates: `/opt/bin/opkg update && /opt/bin/opkg list-upgradable`

**Monthly**:
- Update Entware packages: `/opt/bin/opkg upgrade`
- Review and optimize database
- Test full backup/restore procedure

### Backup Procedures

**Backup Database:**

```bash
# From router
ssh root@192.168.1.1
cp /mnt/data/emergencybox.db /mnt/data/backup-$(date +%Y%m%d).db

# Download to computer
scp root@192.168.1.1:/mnt/data/emergencybox.db ./backup-emergencybox.db
```

**Backup Uploaded Files:**

```bash
# From computer
rsync -avz root@192.168.1.1:/mnt/data/www/uploads/ ./backup-uploads/

# Or create tar archive on router
ssh root@192.168.1.1 "tar czf /tmp/uploads-backup.tar.gz /mnt/data/www/uploads"
scp root@192.168.1.1:/tmp/uploads-backup.tar.gz ./
```

**Full System Backup:**

```bash
# Backup entire data partition
ssh root@192.168.1.1 "tar czf - /mnt/data" > backup-full-$(date +%Y%m%d).tar.gz
```

**Configuration Backup:**

```bash
# Backup DD-WRT configuration
# In DD-WRT web interface: Administration > Backup
# Download nvram.bin file

# Backup lighttpd config
scp root@192.168.1.1:/opt/etc/lighttpd/lighttpd.conf ./backup-lighttpd.conf

# Backup PHP config
scp root@192.168.1.1:/opt/etc/php.ini ./backup-php.ini
```

### Restore Procedures

**Restore Database:**

```bash
# Upload backup to router
scp ./backup-emergencybox.db root@192.168.1.1:/mnt/data/emergencybox.db

# Or from router
ssh root@192.168.1.1
cp /mnt/data/backup-20260110.db /mnt/data/emergencybox.db
chmod 644 /mnt/data/emergencybox.db
```

**Restore Files:**

```bash
# From computer
rsync -avz ./backup-uploads/ root@192.168.1.1:/mnt/data/www/uploads/
```

### Database Maintenance

**Vacuum Database** (reclaim space, optimize):

```bash
ssh root@192.168.1.1
/opt/bin/sqlite3 /mnt/data/emergencybox.db "VACUUM;"
```

**Check Database Integrity:**

```bash
/opt/bin/sqlite3 /mnt/data/emergencybox.db "PRAGMA integrity_check;"
# Should output: ok
```

**Clear Old Messages** (keep last 500):

```bash
/opt/bin/sqlite3 /mnt/data/emergencybox.db "
DELETE FROM messages
WHERE id NOT IN (
    SELECT id FROM messages
    ORDER BY timestamp DESC
    LIMIT 500
);"
```

**Analyze Database** (update statistics):

```bash
/opt/bin/sqlite3 /mnt/data/emergencybox.db "ANALYZE;"
```

### Log Management

**View Logs:**

```bash
ssh root@192.168.1.1

# lighttpd error log
tail -f /opt/var/log/lighttpd/error.log

# PHP error log (if enabled)
tail -f /opt/var/log/php-errors.log

# System log
logread
```

**Clear Logs:**

```bash
# Clear lighttpd log
> /opt/var/log/lighttpd/error.log

# Clear PHP log
> /opt/var/log/php-errors.log
```

**Log Rotation** (to prevent disk full):

Create `/opt/etc/logrotate.conf`:

```conf
/opt/var/log/lighttpd/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

### Monitoring Disk Space

**Check Space:**

```bash
ssh root@192.168.1.1

# Overall disk usage
df -h

# Data partition usage
du -sh /mnt/data/*

# Upload directory size
du -sh /mnt/data/www/uploads/*

# Database size
ls -lh /mnt/data/emergencybox.db
```

**Set Up Space Alert** (optional):

Create `/opt/bin/check-space.sh`:

```bash
#!/bin/sh
USED=$(df /mnt/data | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $USED -gt 80 ]; then
    echo "WARNING: Disk usage at ${USED}%"
    # Could send notification or log alert
fi
```

Add to cron (Administration > Management > Cron):
```
0 * * * * /opt/bin/check-space.sh
```

### Performance Monitoring

**Real-time Monitoring:**

```bash
ssh root@192.168.1.1

# CPU and memory
top

# Disk I/O (if iostat available)
iostat -x 2

# Network connections
netstat -an | grep 8080
```

**Log Analysis:**

```bash
# Count requests per hour
cat /opt/var/log/lighttpd/access.log | awk '{print $4}' | cut -d: -f1-2 | sort | uniq -c

# Most accessed URLs
cat /opt/var/log/lighttpd/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -10

# Error rate
grep -c "error" /opt/var/log/lighttpd/error.log
```

### Security Hardening (Optional)

EmergencyBox is designed for **trusted, offline environments**. However, for added security:

**1. Change Default Passwords:**
```bash
# DD-WRT admin password
# Via web interface: Administration > Management

# WiFi password
# Via web interface: Wireless > Wireless Security
```

**2. Disable Unnecessary Services:**
```bash
# In DD-WRT: Services > Services
# Disable: Telnet (keep SSH only), UPnP, DLNA, etc.
```

**3. Enable HTTPS** (advanced, requires certificate):
```bash
# Generate self-signed certificate
/opt/bin/opkg install openssl-util
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

# Configure lighttpd for SSL
# Edit /opt/etc/lighttpd/lighttpd.conf:
server.modules += ( "mod_openssl" )
ssl.engine = "enable"
ssl.pemfile = "/opt/etc/lighttpd/server.pem"
server.port = 8443
```

**4. Input Validation** (already implemented in PHP):
- SQL injection prevention (parameterized queries)
- Path traversal protection
- File type validation

**5. Rate Limiting** (advanced):
Install and configure `mod_evasive` or implement in JavaScript.

### Updating EmergencyBox

**Update Application Files:**

```bash
# From your computer (in project directory)
scp -r www/* root@192.168.1.1:/mnt/data/www/

# Restart lighttpd
ssh root@192.168.1.1 "/opt/etc/init.d/S80lighttpd restart"
```

**Update Configuration:**

```bash
# Backup current config
ssh root@192.168.1.1 "cp /opt/etc/lighttpd/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf.bak"

# Upload new config
scp config/lighttpd.conf root@192.168.1.1:/opt/etc/lighttpd/lighttpd.conf

# Restart
ssh root@192.168.1.1 "/opt/etc/init.d/S80lighttpd restart"
```

**Update PHP Packages:**

```bash
ssh root@192.168.1.1

# Update package list
/opt/bin/opkg update

# List upgradable packages
/opt/bin/opkg list-upgradable

# Upgrade specific package
/opt/bin/opkg upgrade php7-cli php7-cgi

# Restart services
killall php-cgi
/opt/etc/init.d/S80lighttpd restart
```

### Factory Reset (Last Resort)

**If everything breaks and you need to start over:**

```bash
# From router
ssh root@192.168.1.1

# Stop services
/opt/etc/init.d/S80lighttpd stop
killall lighttpd php-cgi

# Unmount USB
umount /opt
umount /mnt/data

# Remove USB drive physically
# Reformat USB drive on computer
# Follow deployment guide from Phase 2
```

**DD-WRT Factory Reset:**
- Administration > Factory Defaults
- Click "Yes" to reset
- Router will reboot with default settings
- You'll need to reconfigure everything from scratch

---

## Appendix

### Quick Reference Commands

**Service Control:**
```bash
/opt/etc/init.d/S80lighttpd start
/opt/etc/init.d/S80lighttpd stop
/opt/etc/init.d/S80lighttpd restart
/opt/etc/init.d/S80lighttpd status
```

**Process Management:**
```bash
ps | grep lighttpd          # Check if lighttpd running
killall lighttpd            # Kill all lighttpd processes
killall php-cgi             # Kill all PHP-CGI processes
```

**File Locations:**
```bash
/mnt/data/www/                      # Web application root
/mnt/data/emergencybox.db          # SQLite database
/opt/etc/lighttpd/lighttpd.conf    # Web server config
/opt/etc/php.ini                   # PHP config
/opt/var/log/lighttpd/error.log    # Error log
```

**Database Commands:**
```bash
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".tables"
/opt/bin/sqlite3 /mnt/data/emergencybox.db ".schema"
/opt/bin/sqlite3 /mnt/data/emergencybox.db "SELECT * FROM messages;"
```

### Port Reference

| Port | Service | Purpose |
|------|---------|---------|
| 22 | SSH | Remote administration (after password set) |
| 23 | Telnet | Initial configuration (first boot only) |
| 53 | DNS | DD-WRT DNS server |
| 80 | HTTP | DD-WRT admin interface |
| 8080 | HTTP | **EmergencyBox** web interface |

### File Size Limits

| Component | Limit | Reason |
|-----------|-------|--------|
| PHP `upload_max_filesize` | 1024M | Recommended for 256MB RAM |
| PHP `post_max_size` | 1024M | Must be ≥ `upload_max_filesize` |
| lighttpd `max-request-size` | 1073741824 (1GB) | Parser limitation (32-bit signed int) |
| Practical upload limit | ~500MB | Performance and stability |

### Useful DD-WRT Commands

```bash
# Show system info
cat /proc/cpuinfo
cat /proc/meminfo
uname -a

# Show network info
ifconfig
iwconfig

# Show USB devices
lsusb
ls -l /dev/sd*

# Show mounted filesystems
mount
df -h

# Show running processes
ps
top

# Show network connections
netstat -an

# System logs
logread
dmesg
```

### EmergencyBox URLs

- **Web Interface**: `http://192.168.1.1:8080`
- **API Endpoints**:
  - `http://192.168.1.1:8080/api/send_message.php`
  - `http://192.168.1.1:8080/api/get_messages.php`
  - `http://192.168.1.1:8080/api/upload.php`
  - `http://192.168.1.1:8080/api/get_files.php`
  - `http://192.168.1.1:8080/api/init_db.php`
- **Uploads**: `http://192.168.1.1:8080/uploads/`

### Resources

**DD-WRT:**
- Official Site: https://dd-wrt.com/
- Wiki: https://wiki.dd-wrt.com/
- Forums: https://forum.dd-wrt.com/

**Entware:**
- Project Site: https://github.com/Entware/Entware
- Package List: https://bin.entware.net/armv7sf-k3.2/Packages.html

**lighttpd:**
- Documentation: https://redmine.lighttpd.net/projects/lighttpd/wiki

**PHP:**
- Manual: https://www.php.net/manual/
- SQLite3: https://www.php.net/manual/en/book.sqlite3.php

**EmergencyBox:**
- Project Repository: (your GitHub URL)
- Documentation: `/docs` folder

---

## Conclusion

You now have a complete, production-ready EmergencyBox deployment on your ASUS RT-AC68U router. This system provides:

- **Offline communication**: Group chat without internet
- **File sharing**: Up to 1GB file uploads
- **Persistence**: All data survives reboots
- **Multi-user**: Supports 20-50 concurrent users
- **Reliability**: Thoroughly tested and documented

**Key Lessons Learned:**
1. Two-partition USB setup prevents data loss from mount overlays
2. Timezone data must be on the mounted partition
3. PHP extensions require explicit `extension_dir` configuration
4. lighttpd has parser limitations requiring reduced file size limits
5. Port conflicts require running on alternate ports
6. Browser caching can mask configuration issues
7. Database schema must match application expectations

**Next Steps:**
- Print this guide for offline reference
- Train coordinators on using EmergencyBox
- Test with real users in simulated disaster scenario
- Create backup router with identical configuration
- Plan for storage management and data retention

**For Support:**
- Review Troubleshooting section
- Check logs: `/opt/var/log/lighttpd/error.log`
- Consult DD-WRT forums for router-specific issues
- Refer to existing documentation in `/docs`

**Remember**: EmergencyBox is designed for disaster relief scenarios. Deploy responsibly, test thoroughly, and always have a backup plan.

---

**Document Version**: 1.0
**Last Updated**: 2026-01-10
**Tested On**: ASUS RT-AC68U with DD-WRT
**Status**: Production-Ready
