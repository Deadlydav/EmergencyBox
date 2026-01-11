# PHP Compatibility Guide for ASUS RT-AC68U

## The Problem

The ASUS RT-AC68U router presents specific challenges for running PHP:

1. **ARM Architecture**: Limited package availability
2. **Old Kernel**: Some routers run kernel 2.6.36.4
3. **Entware Limitations**: PHP may not be available in all feeds
4. **Memory Constraints**: Only 256MB RAM

## Your Previous Experience

Based on your description:
- **Asuswrt-Merlin + Entware**: PHP packages were not available
- **DD-WRT**: Previously working but installation corrupted
- **Minimalist PHP**: Integration issues

## Solutions Ranked by Reliability

### Option 1: DD-WRT (RECOMMENDED)

**Pros:**
- Better package ecosystem
- More stable PHP support
- You've had it working before
- Community support for RT-AC68U

**Cons:**
- Need to reflash firmware
- Different configuration than Merlin

**Steps:**
1. Flash DD-WRT firmware (latest stable)
2. Factory reset
3. Install Entware/Optware
4. Install PHP 7.x packages
5. Deploy EmergencyBox

**Success Rate:** 85%

### Option 2: Asuswrt-Merlin with Alternative Entware Feed

**Pros:**
- Keep Merlin firmware
- Security updates
- Better VPN support

**Cons:**
- PHP may still not be available
- Requires finding right feed

**Steps:**
```bash
# Try different Entware architecture
wget http://bin.entware.net/armv7sf-k3.2/installer/alternative.sh
sh alternative.sh

# Or try older Entware release
wget http://bin.entware.net/armv7sf-k2.6/installer/generic.sh
sh generic.sh

# Check for PHP
opkg update
opkg list | grep php
```

**Success Rate:** 50%

### Option 3: Compile PHP from Source

**Pros:**
- Full control over PHP version
- Can optimize for router

**Cons:**
- Very time-consuming (hours)
- Requires cross-compilation toolchain
- High complexity
- May fail due to memory constraints

**Steps:**
1. Set up cross-compilation environment
2. Download PHP source
3. Configure with minimal extensions
4. Compile for ARM
5. Transfer to router

**Success Rate:** 30% (for experienced developers)

### Option 4: Pre-compiled PHP Binary

**Pros:**
- Faster than compiling yourself
- Known working configuration

**Cons:**
- Hard to find compatible binary
- Security concerns with random binaries
- May have dependency issues

**Steps:**
1. Search for ARM7 PHP binaries
2. Verify checksums
3. Test on router
4. Resolve dependencies

**Success Rate:** 40%

### Option 5: Alternative Backend (Node.js or Python)

**Pros:**
- Node.js/Python often more available
- Can rewrite EmergencyBox backend
- Potentially better performance

**Cons:**
- Requires rewriting all PHP code
- Different dependencies
- More memory usage

**Backend Options:**
- **Node.js + Express + SQLite3**
- **Python + Flask + SQLite3**
- **BusyBox httpd + Shell scripts** (minimal)

**Success Rate:** 70%

### Option 6: Use PirateBox

**Pros:**
- Designed for routers
- Similar functionality
- Active community
- Known to work on RT-AC68U

**Cons:**
- Less flexible than EmergencyBox
- Limited folder organization
- Harder to customize

**Steps:**
1. Install PirateBox
2. Customize HTML/CSS
3. Modify upload scripts for folders

**Success Rate:** 90%

## Recommended Approach

Based on your requirements and experience:

### Path A: Quick Solution (1-2 hours)
1. Reflash DD-WRT
2. Install Entware
3. Install PHP packages
4. Deploy EmergencyBox
5. Test thoroughly

### Path B: If DD-WRT Fails (3-5 hours)
1. Stay on Merlin
2. Install Node.js via Entware
3. Rewrite EmergencyBox backend in Node.js
4. Keep frontend as-is
5. Deploy and test

### Path C: Minimal Effort (30 minutes - 1 hour)
1. Install PirateBox
2. Customize interface
3. Accept limitations
4. Deploy

## Checking PHP Availability

Before deciding, run these commands on your router:

```bash
# Current firmware and kernel
cat /proc/version

# Entware architecture
opkg print-architecture

# Available PHP packages
opkg update
opkg list | grep -i php

# If PHP available, check version
opkg info php7-cli
opkg info php8-cli
```

## DD-WRT Installation Steps

If you choose DD-WRT (recommended):

### 1. Download Firmware

Get the latest DD-WRT for RT-AC68U:
- https://dd-wrt.com/support/router-database/
- Search for "RT-AC68U"
- Download `.trx` file

### 2. Flash Firmware

**Via Web Interface:**
1. Login to current router admin
2. Administration > Firmware Upgrade
3. Upload DD-WRT .trx file
4. Wait 5-10 minutes
5. Router will reboot

**Via TFTP (if web fails):**
1. Put router in recovery mode
2. Use TFTP client to upload firmware
3. Wait for completion

### 3. Initial Setup

1. Access router at 192.168.1.1
2. Set username/password
3. Basic wireless setup
4. Enable SSH (Services > Services > Secure Shell)

### 4. Prepare USB Drive

```bash
# Format as ext4 on your computer
sudo mkfs.ext4 /dev/sdX1

# Or on router after plugging in
opkg install e2fsprogs
mkfs.ext4 /dev/sda1
```

### 5. Install Entware

```bash
ssh root@192.168.1.1

# Mount USB
mkdir -p /opt
mount /dev/sda1 /opt

# Install Entware
wget http://bin.entware.net/armv7sf-k3.2/installer/generic.sh
sh generic.sh

# Add to startup (Services > Commands > Startup)
sleep 5
mount /dev/sda1 /opt
/opt/etc/init.d/rc.unslung start
```

### 6. Install PHP and Dependencies

```bash
opkg update
opkg install php7-cli php7-cgi php7-mod-sqlite3 php7-mod-fileinfo
opkg install lighttpd lighttpd-mod-fastcgi
opkg install sqlite3-cli

# Verify
php -v
lighttpd -v
```

### 7. Deploy EmergencyBox

```bash
# From your computer
cd emergencybox
./deploy.sh 192.168.1.1 root
```

## Alternative: Node.js Backend

If PHP is not available, here's how to use Node.js:

### Install Node.js

```bash
opkg update
opkg install node node-npm
node --version
```

### Minimal Node.js Server (Alternative Backend)

I can create a Node.js version of the EmergencyBox backend if needed. Let me know if you want this.

Key modules:
- `express` - Web framework
- `better-sqlite3` - SQLite database
- `multer` - File upload handling
- `cors` - Cross-origin requests

## Testing Matrix

Before full deployment, test:

| Test | DD-WRT | Merlin | Node.js | PirateBox |
|------|--------|--------|---------|-----------|
| PHP Available | ✓ | ? | N/A | N/A |
| File Upload <10MB | ✓ | ✓ | ✓ | ✓ |
| File Upload >1GB | ✓ | ? | ✓ | ✓ |
| File Upload 5GB | ? | ? | ? | ? |
| Chat Persistence | ✓ | ✓ | ✓ | ~ |
| Folder Organization | ✓ | ✓ | ✓ | ~ |
| Concurrent Users (10) | ✓ | ✓ | ✓ | ✓ |
| Auto-start | ✓ | ✓ | ✓ | ✓ |

✓ = Likely works
? = Needs testing
~ = Limited support

## My Recommendation

Given your situation:

1. **First Try**: DD-WRT + Entware + PHP
   - You've had success before
   - Best compatibility with EmergencyBox
   - 2-3 hour time investment

2. **Backup Plan**: Keep current Merlin, rewrite backend in Node.js
   - If you prefer Merlin's features
   - More reliable package availability
   - 4-5 hour time investment (I can help with Node.js code)

3. **Last Resort**: PirateBox
   - If everything else fails
   - Limited but functional
   - 1 hour time investment

## Need Help?

Let me know which path you want to take:
- DD-WRT deployment assistance
- Node.js backend rewrite
- PirateBox customization
- Debugging current Merlin setup

I can provide specific commands and code for any of these approaches.
