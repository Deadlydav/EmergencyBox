#!/bin/bash
################################################################################
# EmergencyBox Automated Deployment Script for DD-WRT Routers
#
# This script automates the complete deployment process including critical
# fixes for timezone data, SQLite3, and PHP configuration issues.
#
# Usage:
#   Local execution:  ./deploy.sh [ROUTER_IP] [ROUTER_USER]
#   Remote execution: python3 router_telnet.py "$(cat deploy.sh)"
#
# Requirements:
#   - DD-WRT router with USB storage mounted at /opt
#   - Network connectivity to router
#   - router_telnet.py script for remote execution
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# CONFIGURATION
################################################################################

# Default values (can be overridden by command line arguments)
ROUTER_IP="${1:-192.168.1.1}"
ROUTER_USER="${2:-root}"
ROUTER_PASS="${3:-}"  # Optional: provide password as 3rd argument
DEPLOYMENT_MODE="${4:-local}"  # local or remote

# Paths
ROUTER_BASE="/opt"
ROUTER_SHARE="/opt/share"
ROUTER_WWW="${ROUTER_SHARE}/www"
ROUTER_DATA="${ROUTER_SHARE}/data"
ROUTER_ETC="/opt/etc"
ROUTER_VAR="/opt/var"
LOG_DIR="${ROUTER_VAR}/log/lighttpd"
TMP_DIR="/tmp/emergencybox_deploy"

# Local paths (for file transfer)
LOCAL_BASE="$(cd "$(dirname "$0")" && pwd)"
LOCAL_WWW="${LOCAL_BASE}/www"
LOCAL_CONFIG="${LOCAL_BASE}/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State tracking
ROLLBACK_ENABLED=true
BACKUP_DIR="/tmp/emergencybox_backup_$(date +%Y%m%d_%H%M%S)"

################################################################################
# LOGGING AND OUTPUT FUNCTIONS
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

################################################################################
# ERROR HANDLING AND ROLLBACK
################################################################################

cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"

        if [ "$ROLLBACK_ENABLED" = true ] && [ -d "$BACKUP_DIR" ]; then
            log_warning "Attempting rollback..."
            perform_rollback
        fi
    fi

    # Cleanup temp directory
    rm -rf "$TMP_DIR" 2>/dev/null || true
}

trap cleanup_on_error EXIT

perform_rollback() {
    log_warning "Rolling back to previous state..."

    if [ -d "${BACKUP_DIR}/www" ]; then
        rm -rf "$ROUTER_WWW" 2>/dev/null || true
        mv "${BACKUP_DIR}/www" "$ROUTER_WWW" 2>/dev/null || true
    fi

    if [ -f "${BACKUP_DIR}/lighttpd.conf" ]; then
        mv "${BACKUP_DIR}/lighttpd.conf" "${ROUTER_ETC}/lighttpd/lighttpd.conf" 2>/dev/null || true
    fi

    if [ -f "${BACKUP_DIR}/php.ini" ]; then
        mv "${BACKUP_DIR}/php.ini" "${ROUTER_ETC}/php.ini" 2>/dev/null || true
    fi

    log_success "Rollback completed"
}

################################################################################
# PREREQUISITE CHECKS
################################################################################

check_prerequisites() {
    log_step "STEP 1: Checking Prerequisites"

    # Check if running on router or local machine
    if [ -f "/proc/version" ] && grep -q "DD-WRT" /proc/version 2>/dev/null; then
        log_info "Detected DD-WRT environment - running on router"
        DEPLOYMENT_MODE="router"
    else
        log_info "Running on local machine"

        # Check for required local tools
        for cmd in ssh scp python3; do
            if ! command -v $cmd &> /dev/null; then
                log_error "Required command not found: $cmd"
                exit 1
            fi
        done

        # Check router connectivity
        log_info "Checking router connectivity at ${ROUTER_IP}..."
        if ! ping -c 1 -W 2 "$ROUTER_IP" &> /dev/null; then
            log_error "Cannot reach router at ${ROUTER_IP}"
            exit 1
        fi
        log_success "Router is reachable"
    fi

    # Check USB drive availability
    log_info "Checking USB drive mount..."
    if [ ! -d "$ROUTER_BASE" ]; then
        log_error "/opt directory not found. Is USB drive mounted?"
        log_info "Try: mount | grep /opt"
        exit 1
    fi

    # Check available space
    local available_space=$(df -h "$ROUTER_BASE" | awk 'NR==2 {print $4}')
    log_info "Available space on USB drive: ${available_space}"

    # Check if Entware is installed
    if [ ! -f "${ROUTER_BASE}/bin/opkg" ]; then
        log_warning "Entware not detected. Will install..."
        INSTALL_ENTWARE=true
    else
        log_success "Entware is installed"
        INSTALL_ENTWARE=false
    fi

    log_success "Prerequisites check completed"
}

################################################################################
# ENTWARE INSTALLATION
################################################################################

install_entware() {
    if [ "$INSTALL_ENTWARE" = false ]; then
        return 0
    fi

    log_step "STEP 2: Installing Entware Package Manager"

    # Determine router architecture
    local arch=$(uname -m)
    log_info "Detected architecture: ${arch}"

    # Install Entware
    log_info "Downloading and installing Entware..."

    # Create necessary directories
    mkdir -p /opt/tmp
    cd /opt/tmp

    # Download appropriate installer based on architecture
    # Most ASUS RT-AC68U use ARMv7
    local installer_url="http://bin.entware.net/armv7sf-k3.2/installer/generic.sh"

    if ! wget -O entware_install.sh "$installer_url" 2>&1; then
        log_error "Failed to download Entware installer"
        exit 1
    fi

    # Run installer
    sh entware_install.sh

    # Update package list
    ${ROUTER_BASE}/bin/opkg update

    log_success "Entware installed successfully"
}

################################################################################
# PACKAGE INSTALLATION
################################################################################

install_packages() {
    log_step "STEP 3: Installing Required Packages"

    local OPKG="${ROUTER_BASE}/bin/opkg"

    # Update package lists
    log_info "Updating package lists..."
    $OPKG update

    # List of required packages
    # CRITICAL: php8 and php8-mod-sqlite3 are essential
    local packages=(
        "php8"
        "php8-cgi"
        "php8-cli"
        "php8-mod-sqlite3"
        "php8-mod-session"
        "php8-mod-json"
        "php8-mod-ctype"
        "php8-mod-fileinfo"
        "lighttpd"
        "lighttpd-mod-fastcgi"
        "lighttpd-mod-access"
        "lighttpd-mod-alias"
        "lighttpd-mod-rewrite"
        "lighttpd-mod-setenv"
        "sqlite3-cli"
        "zoneinfo-core"
        "zoneinfo-americas"
        "strace"  # For debugging
        "bash"    # Better shell for scripting
    )

    log_info "Installing packages..."
    for pkg in "${packages[@]}"; do
        log_info "  Installing ${pkg}..."

        # Check if already installed
        if $OPKG list-installed | grep -q "^${pkg} "; then
            log_info "    ${pkg} already installed, upgrading..."
            $OPKG upgrade "$pkg" || log_warning "    Failed to upgrade ${pkg}"
        else
            if ! $OPKG install "$pkg"; then
                log_warning "    Failed to install ${pkg}, continuing..."
            fi
        fi
    done

    # Verify critical packages
    log_info "Verifying critical packages..."

    if [ ! -f "${ROUTER_BASE}/bin/php-cgi" ]; then
        log_error "php-cgi not found after installation"
        exit 1
    fi

    if [ ! -f "${ROUTER_BASE}/bin/php" ]; then
        log_error "php cli not found after installation"
        exit 1
    fi

    # Check PHP version and SQLite support
    log_info "PHP version:"
    ${ROUTER_BASE}/bin/php -v | head -n 1

    log_info "Checking for SQLite3 extension..."
    if ! ${ROUTER_BASE}/bin/php -m | grep -q "sqlite3"; then
        log_error "SQLite3 extension not loaded!"
        log_info "Available PHP modules:"
        ${ROUTER_BASE}/bin/php -m
        exit 1
    fi

    log_success "All required packages installed and verified"
}

################################################################################
# TIMEZONE FIX
# CRITICAL: This fixes the timezone data location issue
################################################################################

fix_timezone() {
    log_step "STEP 4: Fixing Timezone Data"

    # BACKGROUND: PHP looks for timezone data in /usr/share/zoneinfo
    # but Entware installs it to /opt/share/zoneinfo
    # We need to copy or symlink the data to the correct location

    log_info "Checking timezone data..."

    local source_zoneinfo="${ROUTER_SHARE}/zoneinfo"
    local target_zoneinfo="/usr/share/zoneinfo"

    if [ ! -d "$source_zoneinfo" ]; then
        log_error "Zoneinfo source directory not found: ${source_zoneinfo}"
        log_info "Checking if zoneinfo packages are installed..."
        ${ROUTER_BASE}/bin/opkg list-installed | grep zoneinfo
        exit 1
    fi

    log_info "Found timezone data at ${source_zoneinfo}"

    # Create target directory
    mkdir -p "$(dirname "$target_zoneinfo")"

    # Try to create symlink first
    if ln -sf "$source_zoneinfo" "$target_zoneinfo" 2>/dev/null; then
        log_success "Created symlink for timezone data"
        return 0
    fi

    # If symlink fails, the filesystem might not support it (JFFS2)
    log_warning "Symlink failed, attempting to copy timezone data..."

    # CRITICAL FIX: Need to unmount and remount /usr as read-write
    # DD-WRT often has /usr mounted as read-only JFFS2

    log_info "Attempting to remount /usr as read-write..."

    # Find the mount point for /usr
    local usr_mount=$(mount | grep " /usr " | awk '{print $1}')

    if [ -n "$usr_mount" ]; then
        log_info "Found /usr mounted from ${usr_mount}"

        # Try to remount as read-write
        if mount -o remount,rw /usr 2>/dev/null; then
            log_success "Remounted /usr as read-write"

            # Now copy timezone data
            mkdir -p "$target_zoneinfo"
            cp -r "${source_zoneinfo}"/* "$target_zoneinfo/" 2>/dev/null || \
                log_warning "Some timezone files failed to copy"

            # Remount as read-only for safety
            mount -o remount,ro /usr 2>/dev/null || \
                log_warning "Failed to remount /usr as read-only"

            log_success "Timezone data copied successfully"
        else
            log_warning "Could not remount /usr as read-write"
            log_info "Will use TZ environment variable instead"
        fi
    else
        # /usr is not a separate mount, just copy
        mkdir -p "$target_zoneinfo"
        cp -r "${source_zoneinfo}"/* "$target_zoneinfo/" 2>/dev/null || \
            log_warning "Some timezone files failed to copy"

        log_success "Timezone data copied successfully"
    fi

    # Verify timezone data is accessible
    if [ -f "${target_zoneinfo}/UTC" ] || [ -f "${target_zoneinfo}/Etc/UTC" ]; then
        log_success "Timezone data verified"
    else
        log_warning "Timezone data verification failed"
        log_info "PHP will use TZ environment variable"
    fi
}

################################################################################
# PHP CONFIGURATION
################################################################################

configure_php() {
    log_step "STEP 5: Configuring PHP"

    # Backup existing php.ini if it exists
    if [ -f "${ROUTER_ETC}/php.ini" ]; then
        log_info "Backing up existing php.ini..."
        cp "${ROUTER_ETC}/php.ini" "${BACKUP_DIR}/php.ini"
    fi

    # Determine extension directory
    # CRITICAL: PHP needs to know where to find extension .so files
    local ext_dir=$(${ROUTER_BASE}/bin/php -i 2>/dev/null | grep "^extension_dir" | cut -d">" -f2 | tr -d ' ')

    if [ -z "$ext_dir" ]; then
        # Fallback to common location
        ext_dir="${ROUTER_BASE}/lib/php8"
        log_warning "Could not auto-detect extension_dir, using: ${ext_dir}"
    else
        log_info "Detected extension_dir: ${ext_dir}"
    fi

    # Verify extension files exist
    if [ ! -f "${ext_dir}/sqlite3.so" ]; then
        log_error "SQLite3 extension not found at ${ext_dir}/sqlite3.so"
        log_info "Searching for sqlite3.so..."
        find /opt -name "sqlite3.so" 2>/dev/null || true
        exit 1
    fi

    log_info "Creating php.ini..."

    cat > "${ROUTER_ETC}/php.ini" << 'PHPINI'
; EmergencyBox PHP Configuration
; Optimized for DD-WRT router deployment

[PHP]

; Extension directory - CRITICAL: Must match actual location
extension_dir = "EXTENSION_DIR_PLACEHOLDER"

; Core extensions
extension=sqlite3.so
extension=session.so
extension=json.so
extension=ctype.so
extension=fileinfo.so

; Timezone - fallback if zoneinfo files not available
date.timezone = UTC

; Performance and resource limits
max_execution_time = 600
max_input_time = 600
memory_limit = 256M

; File uploads - 5GB support
file_uploads = On
upload_max_filesize = 5G
max_file_uploads = 20
post_max_size = 5G
upload_tmp_dir = /tmp

; Session configuration
session.save_path = /tmp
session.gc_probability = 1
session.gc_divisor = 100

; Error handling
display_errors = Off
log_errors = On
error_log = /tmp/php_errors.log
error_reporting = E_ALL & ~E_NOTICE & ~E_DEPRECATED

; Security
allow_url_fopen = On
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen

; Output buffering
output_buffering = 4096

; SQLite3 specific
sqlite3.extension_dir = "EXTENSION_DIR_PLACEHOLDER"
PHPINI

    # Replace extension_dir placeholder
    sed -i "s|EXTENSION_DIR_PLACEHOLDER|${ext_dir}|g" "${ROUTER_ETC}/php.ini"

    # Set PHPRC environment variable
    # CRITICAL: This tells PHP where to find php.ini
    export PHPRC="${ROUTER_ETC}"

    # Add to profile for persistence
    if ! grep -q "export PHPRC=" /opt/etc/profile 2>/dev/null; then
        echo "export PHPRC=${ROUTER_ETC}" >> /opt/etc/profile
        log_info "Added PHPRC to /opt/etc/profile"
    fi

    # Verify PHP configuration
    log_info "Verifying PHP configuration..."

    if ! ${ROUTER_BASE}/bin/php -c "${ROUTER_ETC}/php.ini" -m | grep -q sqlite3; then
        log_error "PHP cannot load SQLite3 extension"
        log_info "Running PHP diagnostics..."
        ${ROUTER_BASE}/bin/php -c "${ROUTER_ETC}/php.ini" -m
        exit 1
    fi

    log_success "PHP configured successfully"

    # Display configuration summary
    log_info "PHP Configuration Summary:"
    log_info "  PHP Version: $(${ROUTER_BASE}/bin/php -v | head -n1)"
    log_info "  Config File: ${ROUTER_ETC}/php.ini"
    log_info "  Extension Dir: ${ext_dir}"
    log_info "  SQLite3: Enabled"
}

################################################################################
# LIGHTTPD CONFIGURATION
################################################################################

configure_lighttpd() {
    log_step "STEP 6: Configuring Lighttpd Web Server"

    # Create necessary directories
    mkdir -p "${ROUTER_ETC}/lighttpd"
    mkdir -p "$LOG_DIR"
    mkdir -p "${ROUTER_VAR}/run"

    # Backup existing config
    if [ -f "${ROUTER_ETC}/lighttpd/lighttpd.conf" ]; then
        log_info "Backing up existing lighttpd.conf..."
        cp "${ROUTER_ETC}/lighttpd/lighttpd.conf" "${BACKUP_DIR}/lighttpd.conf"
    fi

    log_info "Creating lighttpd.conf..."

    cat > "${ROUTER_ETC}/lighttpd/lighttpd.conf" << 'LIGHTTPDCONF'
## EmergencyBox Lighttpd Configuration
## Optimized for DD-WRT with large file support

server.modules = (
    "mod_access",
    "mod_alias",
    "mod_fastcgi",
    "mod_rewrite",
    "mod_setenv"
)

# Server settings
server.document-root = "/opt/share/www"
server.upload-dirs = ( "/tmp" )
server.errorlog = "/opt/var/log/lighttpd/error.log"
server.pid-file = "/opt/var/run/lighttpd.pid"
server.username = "nobody"
server.groupname = "nogroup"
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
    ".webm" => "video/webm",
    ".ogg" => "audio/ogg",
    "" => "application/octet-stream"
)

# Index files
index-file.names = ( "index.html", "index.php" )

# FastCGI for PHP
# CRITICAL: Must set PHPRC environment variable for PHP to find php.ini
fastcgi.server = (
    ".php" => (
        "localhost" => (
            "socket" => "/tmp/php-fastcgi.socket",
            "bin-path" => "/opt/bin/php-cgi",
            "bin-environment" => (
                "PHP_FCGI_CHILDREN" => "2",
                "PHP_FCGI_MAX_REQUESTS" => "1000",
                "PHPRC" => "/opt/etc"
            ),
            "broken-scriptfilename" => "enable",
            "max-procs" => 2,
            "idle-timeout" => 600
        )
    )
)

# Large file support - CRITICAL for 5GB uploads
server.max-request-size = 5368709120  # 5GB in bytes
server.network-backend = "writev"

# Timeouts for large uploads
server.max-write-idle = 600
server.max-read-idle = 600

# Connection limits
server.max-connections = 50
server.max-fds = 256

# Static file caching
$HTTP["url"] =~ "\.(css|js|jpg|jpeg|png|gif|svg|ico)$" {
    setenv.add-response-header = (
        "Cache-Control" => "public, max-age=3600"
    )
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

$HTTP["url"] =~ "\.db$" {
    url.access-deny = ( "" )
}

# Allow uploads directory access
alias.url = (
    "/uploads/" => "/opt/share/www/uploads/"
)

# Security headers
setenv.add-response-header = (
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "SAMEORIGIN"
)
LIGHTTPDCONF

    # Create init script for lighttpd
    log_info "Creating lighttpd init script..."

    cat > "${ROUTER_ETC}/init.d/S80lighttpd" << 'INITSCRIPT'
#!/bin/sh

PATH=/opt/sbin:/opt/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PHPRC=/opt/etc

DAEMON=/opt/sbin/lighttpd
CONFIG=/opt/etc/lighttpd/lighttpd.conf
PIDFILE=/opt/var/run/lighttpd.pid

start() {
    echo "Starting lighttpd..."

    # Ensure directories exist
    mkdir -p /opt/var/log/lighttpd
    mkdir -p /opt/var/run

    # Clean up stale socket
    rm -f /tmp/php-fastcgi.socket

    # Start lighttpd
    $DAEMON -f $CONFIG

    if [ $? -eq 0 ]; then
        echo "Lighttpd started successfully"
    else
        echo "Failed to start lighttpd"
        exit 1
    fi
}

stop() {
    echo "Stopping lighttpd..."

    if [ -f $PIDFILE ]; then
        kill $(cat $PIDFILE) 2>/dev/null
        rm -f $PIDFILE
        echo "Lighttpd stopped"
    else
        killall lighttpd 2>/dev/null
        echo "Lighttpd stopped (no pidfile)"
    fi

    # Clean up socket
    rm -f /tmp/php-fastcgi.socket
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f $PIDFILE ]; then
        PID=$(cat $PIDFILE)
        if ps | grep -q "^[[:space:]]*$PID "; then
            echo "Lighttpd is running (PID: $PID)"
            return 0
        else
            echo "Lighttpd is not running (stale pidfile)"
            return 1
        fi
    else
        if pgrep lighttpd > /dev/null; then
            echo "Lighttpd is running (no pidfile)"
            return 0
        else
            echo "Lighttpd is not running"
            return 1
        fi
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
INITSCRIPT

    chmod +x "${ROUTER_ETC}/init.d/S80lighttpd"

    log_success "Lighttpd configured successfully"
}

################################################################################
# DEPLOY EMERGENCYBOX FILES
################################################################################

deploy_files() {
    log_step "STEP 7: Deploying EmergencyBox Files"

    # Create directory structure
    log_info "Creating directory structure..."

    mkdir -p "$ROUTER_WWW"
    mkdir -p "${ROUTER_WWW}/css"
    mkdir -p "${ROUTER_WWW}/js"
    mkdir -p "${ROUTER_WWW}/api"
    mkdir -p "${ROUTER_WWW}/uploads/emergency"
    mkdir -p "${ROUTER_WWW}/uploads/media"
    mkdir -p "${ROUTER_WWW}/uploads/documents"
    mkdir -p "${ROUTER_WWW}/uploads/general"
    mkdir -p "$ROUTER_DATA"

    # Backup existing files
    if [ -d "$ROUTER_WWW" ] && [ "$(ls -A $ROUTER_WWW 2>/dev/null)" ]; then
        log_info "Backing up existing web files..."
        mkdir -p "${BACKUP_DIR}/www"
        cp -r "$ROUTER_WWW"/* "${BACKUP_DIR}/www/" 2>/dev/null || true
    fi

    # Check if we're deploying from local machine or on router
    if [ "$DEPLOYMENT_MODE" = "local" ]; then
        log_info "Copying files from local machine to router..."

        # Use SCP to copy files
        scp -r "${LOCAL_WWW}"/* "${ROUTER_USER}@${ROUTER_IP}:${ROUTER_WWW}/" || {
            log_error "Failed to copy web files"
            exit 1
        }

        scp "${LOCAL_CONFIG}/php.ini" "${ROUTER_USER}@${ROUTER_IP}:${ROUTER_ETC}/php.ini" || \
            log_warning "Failed to copy php.ini"

        scp "${LOCAL_CONFIG}/lighttpd.conf" "${ROUTER_USER}@${ROUTER_IP}:${ROUTER_ETC}/lighttpd/lighttpd.conf" || \
            log_warning "Failed to copy lighttpd.conf"

    else
        log_info "Files already present (running on router)"

        # If www directory doesn't exist locally, this is a bootstrap deployment
        # Configuration files have already been created by configure_php and configure_lighttpd
        if [ ! -d "${LOCAL_WWW}" ]; then
            log_warning "www directory not found - using generated configs only"
        fi
    fi

    # Set permissions
    log_info "Setting permissions..."

    chmod -R 755 "$ROUTER_WWW"
    chmod -R 777 "${ROUTER_WWW}/uploads"
    chmod 755 "$ROUTER_DATA"

    # Ensure API files are executable
    if [ -d "${ROUTER_WWW}/api" ]; then
        chmod 644 "${ROUTER_WWW}/api"/*.php 2>/dev/null || true
    fi

    log_success "Files deployed successfully"
}

################################################################################
# INITIALIZE DATABASE
################################################################################

initialize_database() {
    log_step "STEP 8: Initializing Database"

    local init_script="${ROUTER_WWW}/api/init_db.php"

    # Check if init script exists
    if [ ! -f "$init_script" ]; then
        log_warning "init_db.php not found, creating basic database..."

        # Create database manually using sqlite3
        local db_path="${ROUTER_DATA}/emergencybox.db"

        ${ROUTER_BASE}/bin/sqlite3 "$db_path" << 'SQLCREATE'
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
SQLCREATE

        log_success "Database created manually"
    else
        log_info "Running init_db.php..."

        # Set PHPRC for this execution
        export PHPRC="${ROUTER_ETC}"

        # Run initialization script
        if ${ROUTER_BASE}/bin/php -c "${ROUTER_ETC}/php.ini" "$init_script"; then
            log_success "Database initialized successfully"
        else
            log_error "Database initialization failed"
            log_info "Attempting manual creation..."
            initialize_database_manual
        fi
    fi

    # Verify database
    local db_path="${ROUTER_DATA}/emergencybox.db"

    if [ -f "$db_path" ]; then
        log_info "Database file created at: ${db_path}"

        # Check tables
        local tables=$(${ROUTER_BASE}/bin/sqlite3 "$db_path" "SELECT name FROM sqlite_master WHERE type='table';")
        log_info "Database tables: ${tables}"

        # Set permissions
        chmod 666 "$db_path"

        log_success "Database verified and ready"
    else
        log_error "Database file not created"
        exit 1
    fi
}

################################################################################
# START SERVICES
################################################################################

start_services() {
    log_step "STEP 9: Starting Services"

    # Stop services if already running
    log_info "Stopping existing services..."
    "${ROUTER_ETC}/init.d/S80lighttpd" stop 2>/dev/null || true
    sleep 2

    # Clean up stale sockets and pid files
    rm -f /tmp/php-fastcgi.socket
    rm -f "${ROUTER_VAR}/run/lighttpd.pid"

    # Start lighttpd
    log_info "Starting lighttpd..."

    if "${ROUTER_ETC}/init.d/S80lighttpd" start; then
        log_success "Lighttpd started successfully"
    else
        log_error "Failed to start lighttpd"
        log_info "Checking error log..."
        tail -n 20 "${LOG_DIR}/error.log" 2>/dev/null || log_warning "No error log found"
        exit 1
    fi

    # Wait for service to start
    sleep 3

    # Verify service is running
    if "${ROUTER_ETC}/init.d/S80lighttpd" status; then
        log_success "Lighttpd is running"
    else
        log_error "Lighttpd failed to start"
        exit 1
    fi

    # Check if port is listening
    if netstat -ln | grep -q ":8080"; then
        log_success "Lighttpd is listening on port 8080"
    else
        log_warning "Port 8080 not detected, checking configuration..."
    fi
}

################################################################################
# VERIFICATION TESTS
################################################################################

run_verification_tests() {
    log_step "STEP 10: Running Verification Tests"

    local test_failed=false

    # Test 1: Check lighttpd process
    log_info "Test 1: Lighttpd process check"
    if pgrep lighttpd > /dev/null; then
        log_success "  ✓ Lighttpd process running"
    else
        log_error "  ✗ Lighttpd process not found"
        test_failed=true
    fi

    # Test 2: Check PHP-CGI process
    log_info "Test 2: PHP-CGI process check"
    if pgrep php-cgi > /dev/null; then
        log_success "  ✓ PHP-CGI process running"
    else
        log_warning "  ✗ PHP-CGI process not found (will start on first request)"
    fi

    # Test 3: Check listening ports
    log_info "Test 3: Port listening check"
    if netstat -ln | grep -q ":8080"; then
        log_success "  ✓ Port 8080 listening"
    else
        log_error "  ✗ Port 8080 not listening"
        test_failed=true
    fi

    # Test 4: Check web root
    log_info "Test 4: Web root check"
    if [ -f "${ROUTER_WWW}/index.html" ]; then
        log_success "  ✓ Web root accessible"
    else
        log_error "  ✗ index.html not found"
        test_failed=true
    fi

    # Test 5: Check database
    log_info "Test 5: Database check"
    local db_path="${ROUTER_DATA}/emergencybox.db"
    if [ -f "$db_path" ]; then
        log_success "  ✓ Database file exists"

        # Check if we can query it
        if ${ROUTER_BASE}/bin/sqlite3 "$db_path" "SELECT COUNT(*) FROM messages;" &>/dev/null; then
            log_success "  ✓ Database is accessible"
        else
            log_error "  ✗ Database query failed"
            test_failed=true
        fi
    else
        log_error "  ✗ Database file not found"
        test_failed=true
    fi

    # Test 6: Check PHP configuration
    log_info "Test 6: PHP configuration check"
    if [ -f "${ROUTER_ETC}/php.ini" ]; then
        log_success "  ✓ php.ini exists"

        # Test PHP execution
        if ${ROUTER_BASE}/bin/php -c "${ROUTER_ETC}/php.ini" -r "echo 'OK';" &>/dev/null; then
            log_success "  ✓ PHP executes correctly"
        else
            log_error "  ✗ PHP execution failed"
            test_failed=true
        fi

        # Test SQLite3 extension
        if ${ROUTER_BASE}/bin/php -c "${ROUTER_ETC}/php.ini" -m | grep -q sqlite3; then
            log_success "  ✓ SQLite3 extension loaded"
        else
            log_error "  ✗ SQLite3 extension not loaded"
            test_failed=true
        fi
    else
        log_error "  ✗ php.ini not found"
        test_failed=true
    fi

    # Test 7: HTTP request test (if curl/wget available)
    log_info "Test 7: HTTP request test"
    if command -v wget &>/dev/null; then
        if wget -q -O /tmp/test_response.html http://localhost:8080/ 2>/dev/null; then
            log_success "  ✓ HTTP request successful"
            rm -f /tmp/test_response.html
        else
            log_error "  ✗ HTTP request failed"
            test_failed=true
        fi
    elif command -v curl &>/dev/null; then
        if curl -s http://localhost:8080/ > /tmp/test_response.html 2>/dev/null; then
            log_success "  ✓ HTTP request successful"
            rm -f /tmp/test_response.html
        else
            log_error "  ✗ HTTP request failed"
            test_failed=true
        fi
    else
        log_warning "  ⊘ No HTTP client available (wget/curl)"
    fi

    # Test 8: Upload directory permissions
    log_info "Test 8: Upload directory permissions"
    if [ -w "${ROUTER_WWW}/uploads" ]; then
        log_success "  ✓ Upload directory writable"
    else
        log_error "  ✗ Upload directory not writable"
        test_failed=true
    fi

    # Summary
    echo ""
    if [ "$test_failed" = true ]; then
        log_error "Some verification tests failed!"
        log_info "Check the error log: ${LOG_DIR}/error.log"
        return 1
    else
        log_success "All verification tests passed!"
        return 0
    fi
}

################################################################################
# POST-DEPLOYMENT INFORMATION
################################################################################

show_deployment_summary() {
    log_step "Deployment Summary"

    echo ""
    echo "================================================================"
    echo "  EmergencyBox Deployment Complete!"
    echo "================================================================"
    echo ""
    echo "Access Information:"
    echo "  URL:           http://${ROUTER_IP}:8080"
    echo "  Mobile Access: http://192.168.1.1:8080"
    echo ""
    echo "File Locations:"
    echo "  Web Root:     ${ROUTER_WWW}"
    echo "  Database:     ${ROUTER_DATA}/emergencybox.db"
    echo "  Config:       ${ROUTER_ETC}/php.ini"
    echo "  Logs:         ${LOG_DIR}/error.log"
    echo ""
    echo "Service Control:"
    echo "  Start:   ${ROUTER_ETC}/init.d/S80lighttpd start"
    echo "  Stop:    ${ROUTER_ETC}/init.d/S80lighttpd stop"
    echo "  Restart: ${ROUTER_ETC}/init.d/S80lighttpd restart"
    echo "  Status:  ${ROUTER_ETC}/init.d/S80lighttpd status"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:       tail -f ${LOG_DIR}/error.log"
    echo "  Check PHP:       ${ROUTER_BASE}/bin/php -v"
    echo "  Check DB:        ${ROUTER_BASE}/bin/sqlite3 ${ROUTER_DATA}/emergencybox.db"
    echo "  Test PHP:        ${ROUTER_BASE}/bin/php -c ${ROUTER_ETC}/php.ini -i"
    echo ""
    echo "Next Steps:"
    echo "  1. Connect to router WiFi"
    echo "  2. Open browser to http://192.168.1.1:8080"
    echo "  3. Test chat functionality"
    echo "  4. Test file upload"
    echo "  5. Test from multiple devices"
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo "Backup Location: ${BACKUP_DIR}"
        echo "  (Keep this for rollback if needed)"
        echo ""
    fi

    echo "================================================================"
    echo ""
}

################################################################################
# REMOTE EXECUTION WRAPPER
################################################################################

remote_deploy() {
    log_info "Preparing remote deployment via telnet..."

    # Check if router_telnet.py exists
    if [ ! -f "${LOCAL_BASE}/router_telnet.py" ]; then
        log_error "router_telnet.py not found"
        exit 1
    fi

    # Create a self-contained deployment script
    # This will be executed on the router
    local remote_script="/tmp/remote_deploy.sh"

    log_info "Creating remote deployment script..."

    # Copy this script to temp location
    cp "$0" "$remote_script"

    # Execute on router via telnet
    log_info "Executing deployment on router..."
    python3 "${LOCAL_BASE}/router_telnet.py" "sh $(cat $remote_script)"

    rm -f "$remote_script"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    echo ""
    echo "################################################################"
    echo "#                                                              #"
    echo "#         EmergencyBox Automated Deployment Script            #"
    echo "#              for DD-WRT ASUS RT-AC68U Router                #"
    echo "#                                                              #"
    echo "################################################################"
    echo ""

    log_info "Deployment started at $(date)"
    log_info "Router IP: ${ROUTER_IP}"
    log_info "Deployment mode: ${DEPLOYMENT_MODE}"
    echo ""

    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: ${BACKUP_DIR}"
    echo ""

    # Execute deployment steps
    check_prerequisites
    install_entware
    install_packages
    fix_timezone
    configure_php
    configure_lighttpd
    deploy_files
    initialize_database
    start_services

    # Run verification tests
    if run_verification_tests; then
        log_success "Deployment completed successfully!"
    else
        log_warning "Deployment completed with warnings"
    fi

    # Show summary
    show_deployment_summary

    log_info "Deployment finished at $(date)"
}

# Execute main function
main "$@"
