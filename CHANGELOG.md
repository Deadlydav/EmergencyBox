# Changelog

All notable changes to EmergencyBox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### 🎉 Initial Release

First production-ready release of EmergencyBox - offline communication hub for disaster relief.

### Added

#### Core Features
- **Group Chat System**
  - Anonymous messaging with optional usernames
  - Real-time polling (2-second updates)
  - Message priority system
  - File attachment linking
  - Message deletion (admin)
  - Chat history persistence
  - Auto-scroll to latest messages

- **File Sharing Platform**
  - Large file support (up to 1GB per file)
  - Category organization (Documents, Media, Resources, Custom)
  - Upload progress tracking
  - File metadata (name, size, timestamp, uploader)
  - Chunked uploads for reliability
  - File deletion
  - Direct download links

- **Announcement System**
  - Scrolling banner notifications
  - Admin-only announcement creation
  - Persistent announcements across sessions
  - Pause/resume scrolling
  - Clear announcements

- **Admin Features**
  - Separate admin panel (`/admin.html`)
  - Set/clear announcements
  - Clear chat history
  - Database management
  - System monitoring (planned)

#### User Interface
- **Cyberpunk Theme**
  - Neon cyan (#00ffff) primary color
  - Dark background (#0a0e1a)
  - Matrix-style grid background
  - Glowing borders and text shadows
  - Monospace terminal font
  - Responsive design (mobile-friendly)

- **Accessibility**
  - High contrast colors
  - Clear visual feedback
  - Keyboard navigation
  - Screen reader friendly structure

#### Backend
- **Technology Stack**
  - PHP 8.4.7 with FastCGI
  - lighttpd 1.4.79 web server
  - SQLite3 database
  - Entware package management
  - DD-WRT firmware platform

- **Database Schema**
  - `messages` table (chat messages)
  - `files` table (uploaded files metadata)
  - `announcements` table (system announcements)

- **API Endpoints** (11 total)
  - `GET /api/get_messages.php` - Retrieve chat messages
  - `POST /api/send_message.php` - Send new message
  - `POST /api/delete_message.php` - Delete message (admin)
  - `POST /api/clear_chat.php` - Clear all messages (admin)
  - `GET /api/get_files.php` - List uploaded files
  - `POST /api/upload.php` - Upload new file
  - `POST /api/delete_file.php` - Delete file
  - `GET /api/get_announcement.php` - Get current announcement
  - `POST /api/set_announcement.php` - Create announcement (admin)
  - `POST /api/clear_announcement.php` - Clear announcement (admin)
  - `GET /api/init_db.php` - Initialize database schema

#### Deployment
- **Automated Deployment Script** (`deploy.sh`)
  - One-command deployment
  - Prerequisite checking
  - Entware installation
  - Package management
  - Configuration automation
  - Database initialization
  - Service startup
  - Verification testing

- **Hardware Support**
  - ASUS RT-AC68U (primary)
  - DD-WRT v3.0-r63295+
  - USB storage (minimum 8GB recommended)
  - Two-partition architecture (Entware + Data)

- **Remote Management**
  - `router_telnet.py` - Telnet automation
  - `router_ssh.py` - SSH automation (alternative)
  - Credential-free deployment mode

#### Documentation
- **Comprehensive Guides**
  - `README.md` - Project overview and quick start
  - `DEPLOYMENT.md` - Complete deployment guide with troubleshooting
  - `DEPLOYMENT_QUICKSTART.md` - Fast deployment reference
  - `docs/INSTALLATION.md` - Detailed installation steps
  - `docs/USAGE.md` - User guide
  - `docs/DEVELOPMENT.md` - Developer documentation
  - `docs/PHP_COMPATIBILITY.md` - PHP troubleshooting
  - `docs/QUICK_START.md` - Quick reference

- **Docker Emulator**
  - Local testing environment (`EMUL/`)
  - Docker Compose setup
  - Matches production environment
  - Fast development iteration

### Fixed

#### Critical Issues Resolved

1. **PHP Timezone Crash** 🔧
   - **Problem**: PHP-CGI aborted with SIGABRT on startup
   - **Root Cause**: Missing timezone data at `/opt/share/zoneinfo/`
   - **Discovery**: `strace` revealed timezone file lookup failure
   - **Solution**: Timezone files were hidden by USB mount overlay
     - Unmounted `/opt/share`
     - Copied `/opt/share/zoneinfo` to `/tmp`
     - Remounted `/opt/share`
     - Copied timezone data to correct partition
   - **Prevention**: Deployment script handles this automatically

2. **SQLite3 Extension Not Loading** 🔧
   - **Problem**: `Class "SQLite3" not found` errors
   - **Root Cause**: PHP couldn't find extension .so files
   - **Solution**: Added `extension_dir = /opt/lib/php8` to `/opt/etc/php.ini`
   - **Verification**: Extension now loads correctly on startup

3. **lighttpd Upload Size Limit** 🔧
   - **Problem**: Config parser error with `5368709120` (5GB)
   - **Root Cause**: lighttpd 32-bit signed integer limit
   - **Solution**: Reduced to `1073741824` (1GB) which still supports large files
   - **Impact**: Minimal - 1GB is sufficient for emergency scenarios

4. **Port Conflict** 🔧
   - **Problem**: DD-WRT's httpd occupied port 80
   - **Solution**: Configured EmergencyBox on port 8080
   - **Benefit**: DD-WRT admin panel remains accessible on port 80

5. **Database Schema Mismatch** 🔧
   - **Problem**: Manual SQLite schema missing columns (priority, file_id)
   - **Solution**: Use `/api/init_db.php` for proper initialization
   - **Deployment**: Script now calls init_db.php via HTTP

6. **Browser Cache Serving PHP Source** 🔧
   - **Problem**: Browser cached responses when lighttpd was down
   - **Symptom**: JavaScript errors "Unexpected token '<', `<?php` is not valid JSON"
   - **Solution**: Hard refresh (Ctrl+Shift+F5) clears cache
   - **Prevention**: Could add no-cache headers in future

7. **PHPRC Environment Not Set** 🔧
   - **Problem**: FastCGI PHP couldn't find configuration
   - **Solution**: Added `PHPRC => "/opt/etc"` to lighttpd FastCGI environment
   - **Result**: PHP now reads correct php.ini file

### Security

- **Input Sanitization**: All user inputs sanitized before database insertion
- **SQL Injection Prevention**: Prepared statements used throughout
- **XSS Prevention**: HTML entity encoding on output
- **No Authentication**: By design for emergency scenarios (trusted network assumption)
- **File Upload Validation**: Size limits, path traversal prevention
- **Directory Access Control**: `/config/` and `/data/` directories blocked via lighttpd

### Performance

- **Optimizations**
  - 2-second polling interval (configurable)
  - Efficient SQL queries with indexes
  - Chunked file uploads for large files
  - Client-side caching of static assets
  - Minimal JavaScript bundle size

- **Resource Usage**
  - RAM: ~60MB for full stack (lighttpd + PHP + SQLite)
  - Storage: ~30MB for application files
  - Database: Grows with usage (typical: <100MB for thousands of messages)

### Known Issues

- **PHP 8.x Binary Incompatibility**: On some ARM variants, PHP may crash (use strace for diagnosis)
- **Large File Memory**: Uploads >500MB may be slow on routers with <256MB RAM
- **No Push Notifications**: Polling-based updates (offline-first limitation)
- **Browser Compatibility**: Tested on modern browsers (Chrome 90+, Firefox 88+, Safari 14+)

## [Unreleased]

### Planned for v1.1

- User authentication (optional, configurable)
- File search functionality
- Message search
- Export chat history
- Automatic database cleanup
- Performance monitoring dashboard
- Multi-language support (i18n)

### Planned for v1.2

- End-to-end encryption (optional)
- Federation support (multiple routers)
- Voice message recording
- Map/coordinate sharing
- Offline message queue

### Planned for v2.0

- WebRTC peer-to-peer features
- Mesh network support
- Advanced admin controls
- User roles and permissions
- API versioning

---

## Version History

- **1.0.0** (2026-01-10) - Initial public release
- **0.9.0** (2026-01-09) - Beta testing phase
- **0.5.0** (2026-01-08) - Docker emulator developed
- **0.1.0** (2026-01-06) - Project inception

[1.0.0]: https://github.com/yourusername/emergencybox/releases/tag/v1.0.0
[Unreleased]: https://github.com/yourusername/emergencybox/compare/v1.0.0...HEAD
