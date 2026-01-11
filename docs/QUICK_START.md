# EmergencyBox Quick Start Guide

## TL;DR - I Just Want It Working

### Prerequisites
- ASUS RT-AC68U router with DD-WRT or Asuswrt-Merlin
- USB drive (8GB+ recommended)
- SSH access enabled

### Fast Install (5 Steps)

```bash
# 1. SSH into router
ssh admin@192.168.1.1

# 2. Install Entware (if not already installed)
wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh
opkg update

# 3. Install packages
opkg install php7-cli php7-cgi php7-mod-sqlite3 php7-mod-fileinfo
opkg install lighttpd lighttpd-mod-fastcgi sqlite3-cli

# 4. Deploy files (from your computer)
chmod +x deploy.sh
./deploy.sh 192.168.1.1 admin

# 5. Done! Open http://192.168.1.1 in browser
```

---

## Critical PHP Compatibility Note

**IMPORTANT:** The ASUS RT-AC68U has specific PHP compatibility issues:

### If PHP is NOT available in Entware:

**Option 1: Switch to DD-WRT** (Recommended)
- DD-WRT typically has better PHP package support
- More stable for this use case
- See full installation guide in INSTALLATION.md

**Option 2: Use PirateBox Alternative**
- If PHP won't install, you can use PirateBox as the backend
- Modify the system to work with PirateBox's infrastructure
- Not ideal but functional

**Option 3: Manual PHP Compilation**
- Advanced users only
- Time-consuming process
- See: https://www.php.net/manual/en/install.unix.php

### Checking PHP Availability

Before proceeding, verify PHP is available:

```bash
# Check available PHP packages
opkg list | grep php

# Expected output should show php7 or php8 packages
# If nothing appears, PHP is not available in your Entware feed
```

---

## What You Get

- **Group Chat**: Anonymous messaging with priority flags
- **File Sharing**: Upload/download files up to 5GB
- **File Linking**: Reference files in chat messages
- **Offline Operation**: No internet needed
- **Multi-user**: Supports concurrent users

---

## Common Issues

### "PHP packages not found"
**Fix:** Your Entware feed doesn't support PHP. Options:
1. Switch to DD-WRT firmware
2. Try different Entware architecture
3. Use alternative backend (NodeJS, Python)

### "Upload failed"
**Fix:** Check these settings in `/opt/etc/php.ini`:
```ini
upload_max_filesize = 5G
post_max_size = 5G
```
Then restart: `/opt/etc/init.d/S80lighttpd restart`

### "Can't access http://192.168.1.1"
**Fix:**
1. Verify lighttpd is running: `ps | grep lighttpd`
2. Check logs: `tail /opt/var/log/lighttpd/error.log`
3. Restart service: `/opt/etc/init.d/S80lighttpd restart`

### "Database errors"
**Fix:**
```bash
rm /opt/share/data/emergencybox.db
php /opt/share/www/api/init_db.php
```

---

## File Structure Quick Reference

```
Router filesystem:
/opt/share/www/           ← Web files
/opt/share/www/uploads/   ← Uploaded files
/opt/share/data/          ← SQLite database
/opt/etc/lighttpd.conf    ← Web server config
/opt/etc/php.ini          ← PHP config
```

---

## Manual Deployment (Without deploy.sh)

```bash
# On router via SSH:
mkdir -p /opt/share/www/uploads/{emergency,media,documents,general}
mkdir -p /opt/share/data

# From your computer:
cd emergencybox
scp -r www/* admin@192.168.1.1:/opt/share/www/
scp config/php.ini admin@192.168.1.1:/opt/etc/php.ini
scp config/lighttpd.conf admin@192.168.1.1:/opt/etc/lighttpd/lighttpd.conf

# Back on router:
chmod -R 755 /opt/share/www
chmod -R 777 /opt/share/www/uploads
php /opt/share/www/api/init_db.php
/opt/etc/init.d/S80lighttpd restart
```

---

## Testing Checklist

After installation, test these features:

- [ ] Can access http://192.168.1.1
- [ ] Can send a chat message
- [ ] Can send a priority message
- [ ] Can upload a small file (<10MB)
- [ ] Can upload a large file (>100MB)
- [ ] Can download a file
- [ ] Can link a file to a message
- [ ] Can search files
- [ ] Can create custom folder
- [ ] Messages persist after page refresh
- [ ] Files appear in correct categories

---

## Configuration Tweaks

### Change Web Port (from 80 to 8080)

Edit `/opt/etc/lighttpd/lighttpd.conf`:
```
server.port = 8080
```

Access at: `http://192.168.1.1:8080`

### Increase Max File Size to 10GB

1. Edit `/opt/etc/php.ini`:
   ```ini
   upload_max_filesize = 10G
   post_max_size = 10G
   ```

2. Edit `/opt/etc/lighttpd/lighttpd.conf`:
   ```
   server.max-request-size = 10737418240
   ```

3. Edit `/opt/share/www/api/config.php`:
   ```php
   define('MAX_FILE_SIZE', 10 * 1024 * 1024 * 1024);
   ```

4. Restart: `/opt/etc/init.d/S80lighttpd restart`

### Reduce Memory Usage

Edit `/opt/etc/php.ini`:
```ini
memory_limit = 128M  # Down from 256M
```

Edit `/opt/etc/lighttpd/lighttpd.conf`:
```
server.max-connections = 25  # Down from 50
```

---

## Auto-Start on Boot

Create/edit `/jffs/scripts/post-mount`:

```bash
#!/bin/sh
sleep 5
/opt/etc/init.d/S80lighttpd start
```

Make executable:
```bash
chmod +x /jffs/scripts/post-mount
```

---

## Backup and Restore

### Backup

```bash
# From router
scp /opt/share/data/emergencybox.db user@backupserver:/backups/

# Or download to your computer
scp admin@192.168.1.1:/opt/share/data/emergencybox.db ./backup.db
```

### Restore

```bash
# Upload to router
scp backup.db admin@192.168.1.1:/opt/share/data/emergencybox.db
```

---

## Performance Tips

- Use USB 3.0 drive (if supported)
- Format USB as ext4, not FAT32
- Don't run unnecessary services on router
- Limit concurrent users to 10-20 for best performance
- Clear old messages periodically
- Delete unused files to save space

---

## When Things Go Wrong

### Nuclear Option (Full Reset)

```bash
# Backup first!
rm -rf /opt/share/www
rm -rf /opt/share/data
rm /opt/etc/lighttpd/lighttpd.conf

# Then redeploy
./deploy.sh
```

### Check System Resources

```bash
# Disk space
df -h

# Memory usage
free

# Running processes
top

# Web server status
/opt/etc/init.d/S80lighttpd status
```

---

## For Disaster Scenarios

### Pre-Deployment Checklist

- [ ] Router firmware updated and tested
- [ ] Entware/Optware installed and working
- [ ] All packages installed and verified
- [ ] EmergencyBox deployed and tested
- [ ] Auto-start configured
- [ ] Backup of configuration saved
- [ ] Multiple devices tested for connectivity
- [ ] Large file upload/download tested
- [ ] Storage capacity planned
- [ ] WiFi password secured
- [ ] Router physically secured
- [ ] Backup power supply ready (battery/generator)

### In-Field Usage

- Keep router in central, accessible location
- Protect from weather/water damage
- Monitor storage capacity
- Have backup router pre-configured
- Train coordinators on basic troubleshooting
- Keep documentation accessible (print USAGE.md)

---

## Getting Help

1. Check logs: `tail -f /opt/var/log/lighttpd/error.log`
2. Read full INSTALLATION.md for detailed troubleshooting
3. Review DEVELOPMENT.md for customization
4. GitHub Issues: https://github.com/anthropics/claude-code/issues

---

## Next Steps

Once basic installation works:

1. **Customize UI**: Edit `www/css/style.css` for branding
2. **Add categories**: Create custom file categories
3. **Security**: Set strong WiFi password, change router admin password
4. **Test at scale**: Simulate disaster scenario with multiple users
5. **Document local setup**: Note any router-specific quirks
6. **Create backup**: Full system backup before deployment

---

**Remember:** EmergencyBox is designed for offline disaster scenarios. Test thoroughly before actual deployment!
