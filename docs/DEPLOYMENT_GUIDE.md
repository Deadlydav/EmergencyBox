# EmergencyBox Automated Deployment Guide

> **IMPORTANT UPDATE**: For auto-start configuration on boot, see **[AUTOSTART_SETUP.md](../AUTOSTART_SETUP.md)** which documents the `mount --bind` solution for DD-WRT's read-only filesystem.

## Overview

The automated deployment script (`deploy.sh`) provides a complete, unattended installation of EmergencyBox on DD-WRT routers. It handles all critical configuration issues including timezone data, SQLite3 extensions, and PHP configuration.

## Quick Start

### Method 1: Local Execution (Recommended)

Run from your computer with SSH access to the router:

```bash
cd /path/to/emergencybox
chmod +x deploy.sh
./deploy.sh 192.168.1.1 root
```

### Method 2: Remote Execution via Telnet

For routers without SSH but with telnet access:

```bash
python3 router_telnet.py "$(cat deploy.sh)"
```

### Method 3: Direct on Router

Copy the script to the router and execute directly:

```bash
scp deploy.sh root@192.168.1.1:/tmp/
ssh root@192.168.1.1
cd /tmp
./deploy.sh
```

## Deployment Steps

The script performs the following steps automatically:

### Step 1: Prerequisites Check
- Verifies router connectivity
- Checks USB drive availability at `/opt`
- Validates available storage space
- Detects existing Entware installation

### Step 2: Entware Installation
- Detects router architecture (ARMv7 for RT-AC68U)
- Downloads and installs Entware package manager
- Updates package repository lists

### Step 3: Package Installation
- Installs PHP 8 with required extensions:
  - `php8`, `php8-cgi`, `php8-cli`
  - `php8-mod-sqlite3` (CRITICAL)
  - `php8-mod-session`, `php8-mod-json`
  - `php8-mod-ctype`, `php8-mod-fileinfo`
- Installs Lighttpd web server with modules
- Installs SQLite3 CLI tools
- Installs timezone data packages
- Installs debugging tools (strace, bash)

### Step 4: Timezone Fix (CRITICAL)

**Problem:** PHP expects timezone data at `/usr/share/zoneinfo` but Entware installs it to `/opt/share/zoneinfo`

**Solution:** The script attempts multiple strategies:
1. Try to create symlink (preferred)
2. If symlink fails (JFFS2 limitation):
   - Remount `/usr` as read-write
   - Copy timezone files to correct location
   - Remount `/usr` as read-only
3. Falls back to TZ environment variable if all else fails

**Why This Matters:** Without correct timezone data, PHP's date functions will fail, breaking the entire application.

### Step 5: PHP Configuration

**Critical Configurations:**

1. **extension_dir**: Auto-detected from PHP installation
   - Usually `/opt/lib/php8`
   - MUST match actual extension location
   - Verified by checking for `sqlite3.so`

2. **PHPRC Environment Variable**:
   - Set to `/opt/etc` (where php.ini lives)
   - Added to `/opt/etc/profile` for persistence
   - CRITICAL: Without this, PHP won't find php.ini

3. **Upload Limits**:
   - `upload_max_filesize = 5G`
   - `post_max_size = 5G`
   - `max_execution_time = 600` (10 minutes)
   - `memory_limit = 256M`

4. **Extensions Loaded**:
   ```ini
   extension=sqlite3.so
   extension=session.so
   extension=json.so
   extension=ctype.so
   extension=fileinfo.so
   ```

### Step 6: Lighttpd Configuration

**Critical Settings:**

1. **FastCGI Environment Variables**:
   ```
   "PHPRC" => "/opt/etc"
   ```
   This ensures PHP-CGI finds the configuration file.

2. **Large File Support**:
   ```
   server.max-request-size = 5368709120  # 5GB
   server.max-write-idle = 600
   server.max-read-idle = 600
   ```

3. **Port Configuration**:
   - Port 8080 (avoids conflicts with router's web interface on port 80)

4. **Init Script**:
   - Creates `/opt/etc/init.d/S80lighttpd`
   - Provides start/stop/restart/status commands
   - Exports PHPRC before starting

### Step 7: File Deployment

- Creates directory structure under `/opt/share/www`
- Copies all web application files
- Creates upload directories with proper permissions:
  - `/emergency`, `/media`, `/documents`, `/general`
- Sets permissions (755 for web root, 777 for uploads)

### Step 8: Database Initialization

Two methods:

1. **Using init_db.php** (preferred):
   - Runs the PHP initialization script
   - Creates all tables with proper schema

2. **Manual SQLite** (fallback):
   - Uses `sqlite3` CLI directly
   - Creates tables if PHP method fails

**Tables Created:**
- `messages` - Chat messages with priority flags
- `files` - File metadata with categories
- `announcements` - System announcements

### Step 9: Service Startup

- Stops any existing services
- Cleans up stale sockets and PID files
- Starts Lighttpd with proper environment
- Verifies service is running
- Checks port 8080 is listening

### Step 10: Verification Tests

The script runs 8 comprehensive tests:

1. Lighttpd process running
2. PHP-CGI process (spawns on first request)
3. Port 8080 listening
4. Web root accessible (index.html exists)
5. Database file exists and is queryable
6. PHP configuration correct and SQLite3 loaded
7. HTTP request successful (wget/curl test)
8. Upload directory writable

## Critical Fixes Explained

### Fix 1: SQLite3 Extension Loading

**Problem:** PHP can't find sqlite3.so even when installed

**Solution:**
```ini
extension_dir = "/opt/lib/php8"
extension=sqlite3.so
```

**Verification:**
```bash
/opt/bin/php -c /opt/etc/php.ini -m | grep sqlite3
```

### Fix 2: Timezone Data

**Problem:** PHP error: "Timezone database is corrupt"

**Root Cause:**
- PHP compiled to look in `/usr/share/zoneinfo`
- Entware installs to `/opt/share/zoneinfo`
- JFFS2 filesystem doesn't support symlinks

**Solution Hierarchy:**
1. Symlink (if filesystem supports)
2. Copy files after remounting read-write
3. Use TZ environment variable

**Manual Fix if Script Fails:**
```bash
# Remount as read-write
mount -o remount,rw /usr

# Copy timezone data
mkdir -p /usr/share/zoneinfo
cp -r /opt/share/zoneinfo/* /usr/share/zoneinfo/

# Remount as read-only
mount -o remount,ro /usr
```

### Fix 3: PHPRC Environment Variable

**Problem:** PHP-CGI can't find php.ini

**Solution:**
- Set `PHPRC=/opt/etc` in lighttpd FastCGI configuration
- Export PHPRC in init script
- Add to `/opt/etc/profile` for persistence

**Why:** PHP searches for php.ini in multiple locations, but on embedded systems, it may not check `/opt/etc` by default.

### Fix 4: Large File Upload Configuration

**Three Components Must Align:**

1. **PHP (php.ini)**:
   ```ini
   upload_max_filesize = 5G
   post_max_size = 5G
   max_execution_time = 600
   ```

2. **Lighttpd (lighttpd.conf)**:
   ```
   server.max-request-size = 5368709120
   server.max-write-idle = 600
   ```

3. **Application (config.php)**:
   ```php
   define('MAX_FILE_SIZE', 5 * 1024 * 1024 * 1024);
   ```

**All three must match** or uploads will fail at the weakest link.

## Error Handling and Rollback

### Automatic Rollback

The script automatically backs up:
- Existing web files to `/tmp/emergencybox_backup_TIMESTAMP/www/`
- Existing php.ini
- Existing lighttpd.conf

On error, it attempts to restore from backup.

### Manual Rollback

If automatic rollback fails:

```bash
# Stop services
/opt/etc/init.d/S80lighttpd stop

# Restore from backup
BACKUP=/tmp/emergencybox_backup_YYYYMMDD_HHMMSS
cp -r $BACKUP/www/* /opt/share/www/
cp $BACKUP/php.ini /opt/etc/php.ini
cp $BACKUP/lighttpd.conf /opt/etc/lighttpd/lighttpd.conf

# Restart services
/opt/etc/init.d/S80lighttpd start
```

### Disabling Rollback

If you want to prevent rollback (e.g., for debugging):

```bash
# Edit deploy.sh and change:
ROLLBACK_ENABLED=false
```

## Troubleshooting

### Deployment Fails at Entware Installation

**Symptom:** Can't download Entware installer

**Solutions:**
1. Check internet connectivity: `ping 8.8.8.8`
2. Check DNS: `nslookup google.com`
3. Try alternative mirror
4. Manual Entware installation first

### PHP SQLite3 Extension Not Loading

**Diagnosis:**
```bash
/opt/bin/php -c /opt/etc/php.ini -m | grep sqlite3
# Should show "sqlite3"
```

**If missing:**
```bash
# Check extension file exists
ls -l /opt/lib/php8/sqlite3.so

# Check extension_dir in php.ini
grep extension_dir /opt/etc/php.ini

# Try loading manually
/opt/bin/php -c /opt/etc/php.ini -r "var_dump(extension_loaded('sqlite3'));"
```

**Fix:**
```bash
# Find actual extension directory
/opt/bin/php -i | grep extension_dir

# Update php.ini with correct path
vi /opt/etc/php.ini
# Change: extension_dir = "/correct/path"
```

### Timezone Errors Persist

**Symptom:** PHP warnings about timezone database

**Manual Fix:**
```bash
# Check if files exist
ls -l /usr/share/zoneinfo/UTC

# If not, force copy
mount -o remount,rw /usr
mkdir -p /usr/share/zoneinfo
cp -r /opt/share/zoneinfo/* /usr/share/zoneinfo/
mount -o remount,ro /usr

# Or use environment variable
export TZ=UTC
echo 'export TZ=UTC' >> /opt/etc/profile
```

### Lighttpd Won't Start

**Check error log:**
```bash
tail -f /opt/var/log/lighttpd/error.log
```

**Common issues:**

1. **Config syntax error:**
   ```bash
   /opt/sbin/lighttpd -t -f /opt/etc/lighttpd/lighttpd.conf
   ```

2. **Port already in use:**
   ```bash
   netstat -ln | grep 8080
   killall lighttpd
   ```

3. **Missing directories:**
   ```bash
   mkdir -p /opt/var/log/lighttpd
   mkdir -p /opt/var/run
   ```

4. **PHP-CGI not found:**
   ```bash
   which php-cgi
   # Should show /opt/bin/php-cgi
   ```

### Database Initialization Fails

**Manual creation:**
```bash
/opt/bin/sqlite3 /opt/share/data/emergencybox.db << 'EOF'
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT DEFAULT NULL,
    message TEXT NOT NULL,
    priority INTEGER DEFAULT 0,
    file_id INTEGER DEFAULT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    category TEXT NOT NULL,
    size INTEGER NOT NULL,
    uploaded DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS announcements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT NOT NULL,
    active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF

chmod 666 /opt/share/data/emergencybox.db
```

### Services Don't Start on Reboot

**Enable auto-start:**

1. **Via DD-WRT Web Interface:**
   - Administration > Commands
   - Add to Startup:
     ```bash
     /opt/etc/init.d/S80lighttpd start
     ```

2. **Via init.d naming:**
   - The script is named `S80lighttpd` to auto-start
   - Ensure `/opt/etc/init.d/` is in startup path

3. **Manual startup script:**
   ```bash
   # Add to /opt/etc/init.d/rc.local
   #!/bin/sh
   export PHPRC=/opt/etc
   /opt/etc/init.d/S80lighttpd start
   ```

## Testing After Deployment

### Basic Tests

1. **Check services:**
   ```bash
   /opt/etc/init.d/S80lighttpd status
   netstat -ln | grep 8080
   ```

2. **Test web access:**
   ```bash
   wget -O- http://localhost:8080/
   ```

3. **Test PHP:**
   ```bash
   echo "<?php phpinfo(); ?>" > /tmp/test.php
   /opt/bin/php -c /opt/etc/php.ini /tmp/test.php
   ```

4. **Test database:**
   ```bash
   /opt/bin/sqlite3 /opt/share/data/emergencybox.db "SELECT COUNT(*) FROM messages;"
   ```

### Full Application Tests

1. **Access from browser:** http://192.168.1.1:8080
2. **Send a test message** in the chat
3. **Upload a small file** (< 10MB)
4. **Upload a large file** (> 500MB)
5. **Link file to message**
6. **Test from multiple devices** simultaneously

## Performance Tuning

### For Heavy Usage (20+ Users)

Edit `/opt/etc/lighttpd/lighttpd.conf`:

```
server.max-connections = 100
server.max-fds = 512

fastcgi.server = (
    ".php" => (
        "localhost" => (
            "max-procs" => 4,
            "PHP_FCGI_CHILDREN" => "4",
            ...
        )
    )
)
```

Restart: `/opt/etc/init.d/S80lighttpd restart`

### For Limited Memory

Edit `/opt/etc/php.ini`:

```ini
memory_limit = 128M
```

Reduce concurrent processes in lighttpd config:

```
"max-procs" => 1,
"PHP_FCGI_CHILDREN" => "1",
```

## Maintenance

### View Logs

```bash
# Lighttpd error log
tail -f /opt/var/log/lighttpd/error.log

# PHP errors
tail -f /tmp/php_errors.log

# System log
dmesg | tail
```

### Restart Services

```bash
/opt/etc/init.d/S80lighttpd restart
```

### Clear Chat History

```bash
/opt/bin/sqlite3 /opt/share/data/emergencybox.db "DELETE FROM messages;"
```

### Check Disk Space

```bash
df -h /opt
du -sh /opt/share/www/uploads/*
```

### Backup

```bash
# Backup database
cp /opt/share/data/emergencybox.db /tmp/backup_$(date +%Y%m%d).db

# Backup entire application
tar czf /tmp/emergencybox_backup.tar.gz /opt/share/www /opt/share/data
```

## Advanced Configuration

### Custom Domain/Port

Edit `/opt/etc/lighttpd/lighttpd.conf`:

```
server.port = 80  # or any other port
```

Restart: `/opt/etc/init.d/S80lighttpd restart`

### SSL/HTTPS (Not Recommended for Emergency Use)

SSL adds complexity and certificate management. For offline emergency scenarios, HTTP is sufficient within a trusted network.

### Custom Upload Limits

Must change in THREE places:

1. `/opt/etc/php.ini`:
   ```ini
   upload_max_filesize = 10G
   post_max_size = 10G
   ```

2. `/opt/etc/lighttpd/lighttpd.conf`:
   ```
   server.max-request-size = 10737418240  # 10GB
   ```

3. `/opt/share/www/api/config.php`:
   ```php
   define('MAX_FILE_SIZE', 10 * 1024 * 1024 * 1024);
   ```

Restart: `/opt/etc/init.d/S80lighttpd restart`

## Security Considerations

This deployment is designed for **offline, trusted environments**. For production use:

1. **Add authentication:**
   - Implement user login system
   - Use lighttpd's mod_auth

2. **Enable HTTPS:**
   - Generate self-signed certificate
   - Configure SSL in lighttpd

3. **Restrict access:**
   - Firewall rules
   - IP whitelisting
   - VPN access only

4. **File scanning:**
   - Integrate ClamAV
   - Content type validation

## Support and Resources

### Log Files

- Lighttpd: `/opt/var/log/lighttpd/error.log`
- PHP: `/tmp/php_errors.log`
- Deployment: Script output (save to file)

### Useful Commands

```bash
# Check PHP modules
/opt/bin/php -c /opt/etc/php.ini -m

# PHP configuration info
/opt/bin/php -c /opt/etc/php.ini -i

# Test PHP file
/opt/bin/php -c /opt/etc/php.ini /opt/share/www/api/config.php

# SQLite query
/opt/bin/sqlite3 /opt/share/data/emergencybox.db ".tables"

# Check running processes
ps | grep -E '(lighttpd|php)'

# Check listening ports
netstat -ln | grep LISTEN
```

### Getting Help

1. **Check logs first:** Most issues are logged
2. **Run verification tests:** Use test functions in script
3. **Manual verification:** Follow troubleshooting steps
4. **Community:** DD-WRT forums, Entware documentation

## Uninstallation

To completely remove EmergencyBox:

```bash
# Stop services
/opt/etc/init.d/S80lighttpd stop

# Remove files
rm -rf /opt/share/www
rm -rf /opt/share/data
rm /opt/etc/php.ini
rm -rf /opt/etc/lighttpd
rm /opt/etc/init.d/S80lighttpd

# Optional: Remove packages (will affect other apps)
# opkg remove php8 lighttpd sqlite3-cli
```

## Conclusion

The automated deployment script handles all critical configuration issues and provides a robust, production-ready installation of EmergencyBox. The comprehensive error handling, rollback capability, and verification tests ensure reliable deployment even in challenging router environments.

For most users, the script "just works" - but this guide provides the deep knowledge needed for troubleshooting and customization.
