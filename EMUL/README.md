# EmergencyBox Emulator

Docker-based emulation environment for testing EmergencyBox before deploying to actual DD-WRT router hardware.

## What This Is

This emulator creates a containerized environment that closely mimics an ASUS RT-AC68U router running DD-WRT with Entware packages. It allows you to:

- Test EmergencyBox functionality before router deployment
- Debug issues in a controllable environment
- Develop and test changes quickly
- Verify large file uploads work correctly
- Test with multiple concurrent connections

## What's Emulated

### Software Stack
- **PHP 8.2**: Similar to what DD-WRT Entware provides (PHP 7.4-8.2)
- **lighttpd**: Same web server used on router
- **SQLite3**: Same database engine
- **BusyBox**: Router-like utilities
- **Alpine Linux**: Lightweight base (similar to router constraints)

### Hardware Constraints
- **Memory limit**: 256MB (same as RT-AC68U)
- **CPU limit**: 1 core (similar to router)
- **File system**: Similar directory structure (`/opt/share/www`)

### Router Environment
- Same directory paths (`/opt/share/www`, `/opt/share/data`)
- Same file permissions model
- Same service startup sequence
- Same web server configuration

## Prerequisites

- **Docker Desktop** installed (Windows, Mac, or Linux)
- **Docker Compose** (usually included with Docker Desktop)
- At least 2GB free disk space
- Ports 8080 available (maps to router's port 80)

## Quick Start

### Option 1: Automated Testing

```bash
cd EMUL
chmod +x test-emulator.sh
./test-emulator.sh
```

This will:
1. Build the Docker image
2. Start the container
3. Run automated tests
4. Display access URL

### Option 2: Manual Start

```bash
cd EMUL
docker-compose up -d
```

Then open: **http://localhost:8080**

## What Gets Tested

The emulator lets you test:

### ✅ Core Functionality
- [x] Web interface loads
- [x] Chat message sending
- [x] Chat message retrieval
- [x] Priority messages
- [x] File uploads (small files)
- [x] File uploads (large files up to 5GB)
- [x] File downloads
- [x] File categorization
- [x] Custom folder creation
- [x] File-to-chat linking
- [x] File search
- [x] Database persistence
- [x] Auto-refresh polling

### ✅ Technical Aspects
- [x] PHP configuration (upload limits, timeouts)
- [x] lighttpd configuration
- [x] SQLite database operations
- [x] File permissions
- [x] Memory constraints
- [x] Concurrent user handling

## Usage

### Start Emulator

```bash
cd EMUL
docker-compose up -d
```

Access at: http://localhost:8080

### View Logs

```bash
docker-compose logs -f
```

### Stop Emulator

```bash
docker-compose down
```

### Restart Emulator

```bash
docker-compose restart
```

### Access Container Shell

```bash
docker exec -it emergencybox-emulator /bin/bash
```

Once inside:
```bash
# Check database
sqlite3 /opt/share/data/emergencybox.db "SELECT * FROM messages;"

# Check uploaded files
ls -lh /opt/share/www/uploads/

# Check logs
tail -f /opt/var/log/lighttpd/error.log

# Check PHP version
php -v

# Check lighttpd config
cat /etc/lighttpd/lighttpd.conf
```

### Reset Database

```bash
docker exec emergencybox-emulator rm /opt/share/data/emergencybox.db
docker exec emergencybox-emulator php /opt/share/www/api/init_db.php
```

### Reset Everything

```bash
docker-compose down -v  # Remove volumes too
docker-compose up -d
```

## Testing Large File Uploads

### Test 100MB File

```bash
# Create test file
dd if=/dev/zero of=test-100mb.bin bs=1M count=100

# Upload via browser at http://localhost:8080
# Or use curl:
curl -F "file=@test-100mb.bin" -F "category=general" http://localhost:8080/api/upload.php
```

### Test 1GB File

```bash
# Create test file
dd if=/dev/zero of=test-1gb.bin bs=1M count=1024

# Upload via browser (recommended for testing progress bar)
```

### Test 5GB File (Max)

```bash
# Create test file
dd if=/dev/zero of=test-5gb.bin bs=1M count=5120

# Upload via browser
# This tests the absolute maximum supported
```

**Note**: Large file tests may take time depending on your system.

## Development Workflow

### Live Code Editing

The `www/` directory is mounted as a volume, so changes are reflected immediately:

1. Edit files in `../www/`
2. Refresh browser to see changes
3. No need to rebuild container

Example:
```bash
# Edit CSS
nano ../www/css/style.css

# Refresh browser - changes appear immediately!
```

### Testing Configuration Changes

Configuration files require container restart:

1. Edit `lighttpd-emul.conf` or PHP settings in `Dockerfile`
2. Rebuild and restart:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

### Debugging

```bash
# Check if service is running
docker ps

# View real-time logs
docker-compose logs -f

# Check specific log file
docker exec emergencybox-emulator tail -f /opt/var/log/lighttpd/error.log

# Test API directly
curl http://localhost:8080/api/get_messages.php

# Check database contents
docker exec emergencybox-emulator sqlite3 /opt/share/data/emergencybox.db "SELECT * FROM messages;"
```

## Differences from Real Router

### What's the Same
- PHP version (8.2 vs 7.4-8.x on router)
- lighttpd web server
- SQLite database
- File system paths
- Memory constraints
- Upload limits (5GB)

### What's Different
- **OS**: Alpine Linux vs BusyBox/Linux on router
- **CPU**: x86_64 vs ARM on router
- **Network**: Docker network vs actual WiFi
- **Storage**: Docker volume vs USB drive
- **Performance**: Usually faster than actual router

### Why These Differences Don't Matter

The critical components (PHP, lighttpd, SQLite) work identically. If it works in the emulator, it will work on the router (assuming correct PHP version is available).

## Automated Test Suite

The `test-emulator.sh` script runs these tests:

1. ✓ Docker installation check
2. ✓ Docker Compose check
3. ✓ Image build
4. ✓ Container start
5. ✓ Service health check
6. ✓ Homepage loads
7. ✓ Get messages API
8. ✓ Send message API
9. ✓ Get files API
10. ✓ CSS loads
11. ✓ JavaScript loads
12. ✓ Database initialized
13. ✓ Upload directories exist

All tests should show **PASS** in green.

## Multi-User Testing

Test concurrent users:

```bash
# Start emulator
docker-compose up -d

# Open multiple browser windows:
# Window 1: http://localhost:8080
# Window 2: http://localhost:8080 (incognito/private)
# Window 3: http://localhost:8080 (different browser)

# Test:
# - Send messages from different windows
# - Upload files from different windows
# - Verify messages appear in all windows
# - Check database consistency
```

## Stress Testing

Test router-like constraints:

```bash
# Simulate low memory environment (already set to 256MB)
# Upload multiple large files simultaneously
# Send many rapid messages
# Monitor resource usage:

docker stats emergencybox-emulator
```

## Common Issues

### Port 8080 Already in Use

Change port in `docker-compose.yml`:
```yaml
ports:
  - "9090:80"  # Use 9090 instead
```

Then access at: http://localhost:9090

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Common fixes:
docker-compose down
docker system prune -f
docker-compose up -d --build
```

### Database Locked

```bash
# Stop container
docker-compose down

# Remove database volume
docker volume rm emul_emergencybox-data

# Restart
docker-compose up -d
```

### Upload Fails

Check container logs:
```bash
docker-compose logs -f
```

Common issues:
- File too large (>5GB)
- PHP timeout (increase in Dockerfile)
- Disk space (check Docker disk usage)

## Performance Benchmarks

Expected performance in emulator:

| Metric | Emulator | Actual Router |
|--------|----------|---------------|
| Small file upload (<10MB) | <1s | 1-2s |
| Large file upload (1GB) | 20-60s | 60-120s |
| Message send latency | <100ms | 100-200ms |
| Database query | <10ms | 10-50ms |
| Concurrent users | 50+ | 20-30 |

## Next Steps After Testing

Once emulator tests pass:

1. ✓ Verify all features work
2. ✓ Test large file uploads (>1GB)
3. ✓ Test concurrent users
4. ✓ Check database persistence
5. → Deploy to actual router (see `../docs/INSTALLATION.md`)

## Cleanup

Remove everything:

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (deletes all data)
docker-compose down -v

# Remove image
docker rmi emul_emergencybox
```

## Tips

- Use Chrome DevTools Network tab to debug API calls
- Check browser console for JavaScript errors
- Monitor container stats: `docker stats`
- Test on phone/tablet by accessing `http://<your-ip>:8080`
- Create test files: `dd if=/dev/urandom of=test.bin bs=1M count=50`

## Support

If emulator works but router doesn't:
1. Check PHP version matches: `php -v`
2. Verify router has enough space: `df -h`
3. Check router logs: `tail -f /opt/var/log/lighttpd/error.log`
4. Compare configs: emulator vs router
5. See `../docs/INSTALLATION.md` troubleshooting section

---

**The emulator is ready!** Run `./test-emulator.sh` to get started.
