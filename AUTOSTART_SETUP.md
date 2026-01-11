# EmergencyBox Auto-Start Configuration

This guide explains how to configure EmergencyBox to start automatically when your DD-WRT router boots.

## Prerequisites

- DD-WRT router with USB port
- USB drive with two partitions:
  - `/dev/sda1` (ext4) - EmergencyBox application files
  - `/dev/sda2` (ext4) - Entware packages
- Entware already installed on sda2
- EmergencyBox files deployed to `/tmp/mnt/sda1/www`

## The Problem with DD-WRT

DD-WRT has a **read-only root filesystem** after boot, which prevents creating symlinks in `/opt`. Traditional approaches like `rm -rf /opt && ln -s /tmp/mnt/sda2 /opt` fail because:
1. Root filesystem becomes read-only shortly after boot
2. `/opt` exists as a directory in the firmware
3. You cannot remove or replace it

## The Solution: mount --bind

The `mount --bind` command allows you to **overlay** a directory on top of another, even on read-only filesystems:

```bash
mount --bind /tmp/mnt/sda2 /opt
```

This makes `/opt` point to the USB partition content without needing to modify the root filesystem.

## Installation Steps

### Method 1: Web Interface (Recommended)

1. **Open DD-WRT Web Interface**
   ```
   http://192.168.1.1
   ```

2. **Navigate to Commands Section**
   ```
   Administration → Commands
   ```

3. **Paste Startup Script**

   Copy the contents of `startup_script.sh` into the "Startup" text box.

4. **Save Configuration**

   Click **"Save Startup"** button at the bottom of the Commands section.

5. **Reboot Router**
   ```bash
   # Via web interface:
   Administration → Management → Reboot Router

   # Or via telnet/SSH:
   reboot
   ```

6. **Wait and Test**

   Wait 60-90 seconds for the router to fully boot, then test:
   ```
   http://192.168.1.1:8080
   ```

### Method 2: Python Script (Automated)

**Note**: The web API method may not work reliably on all DD-WRT versions. If it fails, use Method 1.

```bash
python3 scripts/setup_autostart_web.py
```

## Startup Script Explanation

```bash
sleep 5
# Wait for system to fully boot before running commands

while [ ! -b /dev/sda2 ]; do sleep 1; done
# Wait for USB device to be detected (block device exists)

mkdir -p /tmp/mnt/sda1 /tmp/mnt/sda2
# Create mount points

mount /dev/sda2 /tmp/mnt/sda2 2>/dev/null
mount /dev/sda1 /tmp/mnt/sda1 2>/dev/null
# Mount USB partitions (suppress errors if automount already did it)

mount --bind /tmp/mnt/sda2 /opt
# KEY FIX: Overlay Entware directory over /opt

mkdir -p /opt/share
ln -sfn /tmp/mnt/sda1/www /opt/share/www
# Create symlink for web files

/opt/etc/init.d/rc.unslung start
# Start Entware services

sleep 3
# Wait for services to initialize

/opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf &
# Start web server in background
```

## Troubleshooting

### EmergencyBox not accessible after reboot

1. **Check if router has booted**
   ```bash
   ping 192.168.1.1
   ```

2. **Verify USB is mounted**
   ```bash
   python3 scripts/router_telnet.py "mount | grep sda"
   ```
   Should show both sda1 and sda2 mounted.

3. **Check if mount --bind worked**
   ```bash
   python3 scripts/router_telnet.py "ls -la /opt/sbin/lighttpd"
   ```
   Should show the lighttpd binary exists.

4. **Check if lighttpd is running**
   ```bash
   python3 scripts/router_telnet.py "ps | grep lighttpd"
   ```

5. **View startup script in NVRAM**
   ```bash
   python3 scripts/router_telnet.py "nvram get rc_startup"
   ```
   **Note**: This only works if you configured via web interface. The web interface stores commands differently than NVRAM.

### Manual Start (if auto-start fails)

```bash
python3 scripts/router_telnet.py "mount --bind /tmp/mnt/sda2 /opt && mkdir -p /opt/share && ln -sfn /tmp/mnt/sda1/www /opt/share/www && /opt/sbin/lighttpd -f /opt/etc/lighttpd/lighttpd.conf"
```

## Key Technical Points

### Why mount --bind?

- **Works on read-only filesystems**: Doesn't require modifying root
- **Survives across operations**: Can be done after boot
- **Transparent to applications**: Programs see `/opt` as if it's the real location

### Why not use NVRAM rc_startup?

Testing showed that `nvram set rc_startup=...` doesn't reliably execute on DD-WRT. The web interface uses a different mechanism that works more consistently.

### USB Automount

- **Enabled by default**: `nvram get usb_automnt` returns `1`
- **Required for ext4**: DD-WRT kernel lacks built-in ext4 module
- **Automount loads ext4**: Uses special mechanisms to enable ext4 support
- **Script is idempotent**: Mounting already-mounted partitions is safe (errors suppressed)

## Testing After Reboot

After router reboots, run these checks:

```bash
# 1. Ping router
ping -c 3 192.168.1.1

# 2. Check mount points
python3 scripts/router_telnet.py "mount | grep sda"

# 3. Check /opt overlay
python3 scripts/router_telnet.py "ls /opt/sbin/lighttpd"

# 4. Check lighttpd process
python3 scripts/router_telnet.py "ps | grep lighttpd"

# 5. Test web interface
curl http://192.168.1.1:8080
```

## Files Modified

- **DD-WRT**: Startup commands (via web interface)
- **This repository**:
  - `startup_script.sh` - The startup script content
  - `AUTOSTART_SETUP.md` - This documentation

## References

- DD-WRT Wiki: https://wiki.dd-wrt.com/wiki/index.php/Startup_Scripts
- Entware on DD-WRT: https://github.com/Entware/Entware/wiki/Install-on-DD-WRT
- mount(8) manual: `man mount`
