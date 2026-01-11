#!/bin/bash
# EmergencyBox Service Startup Script
# Mimics DD-WRT router boot sequence

set -e

echo "================================================"
echo "  Starting EmergencyBox Emulation Environment"
echo "================================================"
echo ""

# Display system info (like router would)
echo "System Information:"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "  PHP: $(php82 -v | head -n1)"
echo "  lighttpd: $(lighttpd -v | head -n1)"
echo ""

# Initialize database if it doesn't exist
if [ ! -f /opt/share/data/emergencybox.db ]; then
    echo "Initializing database..."
    php82 /opt/share/www/api/init_db.php
    echo "Database initialized!"
else
    echo "Database already exists, skipping initialization"
fi

# Set correct permissions (router-like environment)
echo "Setting permissions..."
chmod -R 755 /opt/share/www
chmod -R 777 /opt/share/www/uploads
chmod 777 /opt/share/data
chmod 666 /opt/share/data/emergencybox.db 2>/dev/null || true

# Create log directory if needed
mkdir -p /opt/var/log/lighttpd
touch /opt/var/log/lighttpd/error.log
chmod 777 /opt/var/log/lighttpd/error.log

# Display configuration
echo ""
echo "EmergencyBox Configuration:"
echo "  Web root: /opt/share/www"
echo "  Database: /opt/share/data/emergencybox.db"
echo "  Uploads: /opt/share/www/uploads"
echo "  Logs: /opt/var/log/lighttpd/error.log"
echo ""

# Start lighttpd in foreground
echo "Starting lighttpd web server..."
echo "Access EmergencyBox at: http://localhost:8080"
echo ""
echo "================================================"
echo "  EmergencyBox is now running!"
echo "================================================"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start lighttpd (foreground mode for Docker)
exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
