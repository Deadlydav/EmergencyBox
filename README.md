# EmergencyBox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: DD-WRT](https://img.shields.io/badge/Platform-DD--WRT-blue.svg)](https://dd-wrt.com)
[![PHP: 8.4.7](https://img.shields.io/badge/PHP-8.4.7-777BB4.svg)](https://www.php.net/)
[![Status: Work in Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-yellow.svg)]()
[![Core Features: Working](https://img.shields.io/badge/Core%20Features-Working-success.svg)]()

> A self-contained, offline communication and coordination system for disaster relief scenarios inspired-by-piratebox. Turn your router into a lifeline when the internet goes down.

## ⚠️ Project Status: Work in Progress

**Core Features (Working ✅):**
- ✅ Group chat system with real-time updates
- ✅ File sharing (up to 5GB files)
- ✅ SQLite database backend
- ✅ Offline-first architecture
- ✅ Multi-user support (20-50 concurrent)

**In Development (Planned 🎯):**
- 🎯 ATAK-style tactical mapping (offline OpenStreetMap)
- 🎯 Voice message support

**⚠️ Not production-ready:** This project is actively under development. While chat and file transfer work reliably, deployment procedures and mapping features are still being refined. Use at your own risk in non-critical scenarios.

See [ATAK.md](ATAK.md) for planned mapping features and [COMPETITION.md](COMPETITION.md) for project positioning.

![EmergencyBox Banner](https://via.placeholder.com/1200x300/0a0e27/00f5ff?text=EmergencyBox+-+Offline+Communication+Hub)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware Requirements](#hardware-requirements)
- [Quick Start](#quick-start)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Security Considerations](#security-considerations)
- [User Interface](#user-interface)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**EmergencyBox** transforms an ASUS RT-AC68U router into a standalone Wi-Fi hotspot that provides critical communication infrastructure when traditional networks fail. Designed specifically for disaster relief, emergency response, and remote coordination scenarios where internet connectivity is unavailable or compromised.

### Why EmergencyBox?

- **No Internet Required** - Operates completely offline on an isolated network
- **Instant Deployment** - Plug in, power on, connect
- **Multi-User Support** - 20-50 concurrent users on a single router
- **Disaster-Resilient** - Built for harsh environments and unreliable power
- **No Authentication** - By design for emergency scenarios - anyone can connect and help
- **Router-Based** - Leverages existing hardware, no servers needed

### Use Cases

- **Disaster Relief Operations** - Coordinate rescue teams, share critical information
- **Emergency Response** - First responder communication in infrastructure-down scenarios
- **Remote Communities** - Communication hub for areas without internet access
- **Field Operations** - Military, research expeditions, construction sites
- **Event Coordination** - Large gatherings in remote locations

---

## Features

### Group Chat System ✅ Working
- **Anonymous Messaging** - No account creation, no login required
- **Priority Messages** - Flag urgent communications for visibility
- **File Linking** - Reference shared files directly in chat messages
- **Real-Time Updates** - 2-second polling for near-instant message delivery
- **Message Persistence** - SQLite database stores complete chat history
- **Username Support** - Optional usernames for coordination (not authentication)

### File Sharing Platform ✅ Working
- **Large File Support** - Upload files up to 1GB (configurable to 5GB+)
- **Category Organization** - Emergency, Media, Documents, General folders
- **Custom Folders** - Create new directories on-the-fly
- **Progress Tracking** - Visual upload progress with speed and ETA
- **File Browser** - Search, filter, and download shared resources
- **File Metadata** - Automatic file type detection and size formatting

### Tactical Mapping 🎯 Planned (ATAK-Inspired)
- **Offline OpenStreetMap Tiles** - Pre-downloaded maps for disaster areas
- **Tactical Markers** - Hazards, safe zones, medical, water sources, meeting points
- **Distance & Area Tools** - Measure distances and areas for planning
- **Route Planning** - Multi-waypoint route creation with distance calculation
- **Coordinate Sharing** - Share locations directly in group chat
- **Photo Markers** - Attach photos to map locations
- **Geolocation Tracking** - Optional GPS position sharing (client-side)
- **Layer Filtering** - Toggle marker types on/off for clarity

See [ATAK.md](ATAK.md) for complete tactical mapping specification and implementation roadmap.

### Offline-First Design ✅ Working
- **Zero Internet Dependency** - All processing on-router
- **SQLite Backend** - Embedded database, no external services
- **Vanilla JavaScript** - No CDN dependencies, works completely offline
- **USB Storage** - Expandable storage via USB drives
- **Auto-Recovery** - Survives power cycles and router reboots

### Admin Features ✅ Working
- **Announcements** - Broadcast important messages to all users
- **Chat Moderation** - Clear chat history when needed
- **File Management** - Delete files, manage storage
- **System Monitoring** - Connection status, user count

### Planned Enhancements 🎯
- **Voice Messages** - Record and share audio messages
- **Image Thumbnails** - Preview images in file browser
- **Message Search** - Search chat history

---

## Hardware Requirements

### Compatible Routers

**Primary Support:**
- ASUS RT-AC68U (Recommended)
- ASUS RT-AC66U
- ASUS RT-N66U

**Potentially Compatible:**
- Other ASUS routers with ARM architecture
- High-end DD-WRT compatible routers (256MB+ RAM)

### Router Specifications

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| RAM | 256MB | 512MB+ |
| CPU | ARM Cortex-A9 | Dual-core 1GHz+ |
| Firmware | DD-WRT or Asuswrt-Merlin | DD-WRT (better PHP support) |
| USB Port | USB 2.0 | USB 3.0 |

### USB Storage Requirements

**Two-Partition Setup:**

1. **Partition 1 (Entware)** - ext4 filesystem
   - Minimum: 2GB
   - Stores: Entware packages, PHP, lighttpd, SQLite

2. **Partition 2 (Data)** - ext4 filesystem
   - Minimum: 8GB
   - Recommended: 32GB - 128GB
   - Stores: Web application, uploads, database

**USB Drive Recommendations:**
- USB 3.0 for faster transfers
- ext4 formatted (not FAT32)
- Quality brands for reliability (SanDisk, Samsung, Kingston)
- Consider dual-USB setup for redundancy

### Network Setup

- **WiFi Standard**: 802.11ac (5GHz) or 802.11n (2.4GHz)
- **Expected Range**: 150-300 feet indoors
- **Concurrent Users**: 20-30 recommended, 50 maximum
- **IP Configuration**: Static IP recommended (192.168.1.1)

---

## Quick Start

### Prerequisites
- ASUS RT-AC68U router with DD-WRT firmware
- USB drive (8GB+, formatted as ext4)
- SSH access to router
- Basic Linux command line knowledge

### Installation in 5 Minutes

```bash
# 1. SSH into your router
ssh root@192.168.1.1

# 2. Install Entware package manager
wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh
opkg update

# 3. Install required packages
opkg install php8-cli php8-cgi php8-mod-sqlite3 php8-mod-fileinfo \
             lighttpd lighttpd-mod-fastcgi sqlite3-cli

# 4. Deploy EmergencyBox from your computer
cd emergencybox
chmod +x deploy.sh
./deploy.sh 192.168.1.1 root

# 5. Access the interface
# Open browser: http://192.168.1.1
```

### Verify Installation

1. **Connect** to the router's WiFi network
2. **Navigate** to `http://192.168.1.1` in your browser
3. **Test** sending a chat message
4. **Upload** a small file to verify file sharing
5. **Refresh** page to confirm message persistence

### Next Steps

- Read [INSTALLATION.md](docs/INSTALLATION.md) for detailed setup
- Review [USAGE.md](docs/USAGE.md) for user guide
- Check [QUICK_START.md](docs/QUICK_START.md) for fast reference

---

## Technology Stack

### Backend Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Web Server | lighttpd | Latest | Lightweight HTTP server optimized for embedded systems |
| Application | PHP | 8.4.7 | Server-side scripting and API layer |
| Database | SQLite3 | 3.x | Embedded relational database for messages |
| Package Manager | Entware | Latest | ARM package repository for DD-WRT |
| Firmware | DD-WRT | Latest | Router operating system |

### Frontend Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| HTML5 | Semantic markup | Modern, accessible interface |
| CSS3 | Custom cyberpunk theme | No framework overhead |
| JavaScript | Vanilla ES6+ | Zero dependencies, works offline |
| AJAX | XMLHttpRequest | Polling-based real-time updates |

### Storage Architecture

```
USB Drive (ext4)
├── /opt/share/www/           # Web application root
│   ├── index.html            # Main interface
│   ├── admin.html            # Admin panel
│   ├── css/style.css         # Cyberpunk theme
│   ├── js/app.js             # Frontend logic
│   ├── api/*.php             # Backend APIs
│   └── uploads/              # File storage
│       ├── emergency/
│       ├── media/
│       ├── documents/
│       └── general/
└── /opt/share/data/
    └── emergencybox.db       # SQLite database
```

### API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/send_message.php` | POST | Send chat message |
| `/api/get_messages.php` | GET | Retrieve chat history |
| `/api/delete_message.php` | POST | Delete specific message |
| `/api/clear_chat.php` | POST | Clear all messages |
| `/api/upload.php` | POST | Upload file with chunking |
| `/api/get_files.php` | GET | List uploaded files |
| `/api/delete_file.php` | POST | Delete uploaded file |
| `/api/set_announcement.php` | POST | Set announcement banner |
| `/api/get_announcement.php` | GET | Retrieve current announcement |
| `/api/clear_announcement.php` | POST | Clear announcement |
| `/api/init_db.php` | GET | Initialize database schema |

---

## Architecture

### Design Philosophy

EmergencyBox is built on three core principles:

1. **Offline-First** - No external dependencies, no internet required
2. **Router-Based** - Leverage existing hardware, minimal additional equipment
3. **Emergency-Ready** - Simple, reliable, works when everything else fails

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     USERS (Devices)                         │
│  📱 Smartphones  💻 Laptops  📱 Tablets  🖥️ Desktops       │
└──────────────┬──────────────────────────────────────────────┘
               │
               │ WiFi (802.11ac/n)
               │ No Internet Required
               │
┌──────────────▼──────────────────────────────────────────────┐
│              ASUS RT-AC68U Router (DD-WRT)                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              EmergencyBox Application               │  │
│  │                                                      │  │
│  │  Frontend (HTML/CSS/JS) ←→ Backend (PHP APIs)      │  │
│  │           ↓                        ↓                 │  │
│  │     Browser Display          SQLite Database        │  │
│  │                                    ↓                 │  │
│  │                              File Storage (USB)     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │            System Services (Entware)                │  │
│  │  • lighttpd (Web Server)                            │  │
│  │  • PHP 8.4.7 (FastCGI)                              │  │
│  │  • SQLite3 (Database Engine)                        │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
               │
               │ USB 3.0 Connection
               │
┌──────────────▼──────────────────────────────────────────────┐
│                   USB Storage Drive                         │
│  Partition 1: Entware (ext4, 2GB)                          │
│  Partition 2: Data (ext4, 8-128GB)                         │
└─────────────────────────────────────────────────────────────┘
```

### Why Router-Based?

**Advantages over traditional server deployments:**

- **Portability** - Fits in a backpack, deploy anywhere
- **Power Efficiency** - 15W power consumption vs 200W+ for servers
- **Built-in WiFi** - No additional access points needed
- **Cost-Effective** - Use existing hardware, under $50 used
- **Familiar Interface** - Everyone knows how to connect to WiFi
- **Battery Compatible** - Can run on portable power banks
- **Rugged** - Designed for consumer use, handles temperature/humidity

### Why Two-Partition USB Setup?

**Partition 1 (Entware):**
- System packages and dependencies
- Survives across EmergencyBox updates
- Can be reused for other router projects

**Partition 2 (Data):**
- Application code and user data
- Easy backup and restore
- Swappable between routers for redundancy
- Can be mounted read-only for security

### Why SQLite?

- **Embedded** - No separate database server process
- **Reliable** - ACID compliant, handles power failures
- **Fast** - Sufficient for 50 concurrent users
- **Simple** - Single file database, easy backup
- **Portable** - Database file can be moved between systems

### Why PHP on DD-WRT?

- **Availability** - DD-WRT has mature PHP packages
- **Performance** - Sufficient for embedded use
- **Ecosystem** - Large library of code examples
- **SQLite Support** - Native PHP-SQLite integration
- **Low Memory** - Runs in 256MB RAM environments

---

## Security Considerations

### Threat Model

EmergencyBox is designed for **offline, isolated, trusted networks** in emergency scenarios. It is **NOT designed for internet-facing or hostile environments**.

### What's Included

| Security Feature | Status | Notes |
|------------------|--------|-------|
| Input Sanitization | ✅ Implemented | PHP input filtering on all endpoints |
| SQL Injection Prevention | ✅ Implemented | Parameterized SQLite queries |
| Path Traversal Protection | ✅ Implemented | File upload directory restrictions |
| File Type Validation | ✅ Implemented | MIME type checking |
| XSS Prevention | ✅ Implemented | Output escaping in JavaScript |
| CSRF Tokens | ❌ Not implemented | Not needed for offline use |
| Rate Limiting | ⚠️ Basic | Simple flood protection |

### What's NOT Included

| Security Feature | Status | Rationale |
|------------------|--------|-----------|
| User Authentication | ❌ By design | Emergency scenarios require open access |
| Encryption (HTTPS) | ❌ Not implemented | Local network, self-signed certs problematic |
| File Malware Scanning | ❌ Not implemented | No AV available for ARM routers |
| Access Control Lists | ❌ Not implemented | All users trusted in disaster scenarios |
| Audit Logging | ⚠️ Minimal | Basic logs only, no user tracking |
| Content Filtering | ❌ Not implemented | Trusted user assumption |

### Security Recommendations

**If deploying in less-trusted environments:**

1. **Enable WiFi Encryption** - Use WPA2/WPA3 with strong passphrase
2. **Change Default Passwords** - Router admin password must be changed
3. **Disable WAN Access** - Block all external connections
4. **Add HTTPS** - Generate self-signed certificates for encryption
5. **Implement Authentication** - Add simple password protection
6. **Enable Logging** - Monitor access and uploads
7. **Regular Backups** - Backup database and critical files
8. **Network Isolation** - Run on dedicated WiFi network

### Known Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Malicious File Upload | High | Manual review, trusted users only |
| Storage Exhaustion | Medium | Monitor disk space, set quotas |
| Chat Abuse/Spam | Low | Admin clear chat function |
| Unauthorized Access | Medium | WiFi password, physical security |
| Data Loss | Medium | Regular backups, redundant hardware |

### Emergency Security Protocol

**For disaster relief deployments:**

1. **Physical Security** - Secure router in locked container
2. **WiFi Password** - Share only with authorized personnel
3. **Data Review** - Periodically review uploaded content
4. **Clean Shutdown** - Backup before powering down
5. **Incident Response** - Clear chat/files if compromised

---

## User Interface

### Cyberpunk Dark Theme

EmergencyBox features a custom-designed cyberpunk aesthetic built for readability in low-light emergency conditions.

**Color Palette:**
- **Cyber Cyan** (#00f5ff) - Primary actions, links
- **Cyber Pink** (#ff006e) - Danger actions, priority messages
- **Cyber Purple** (#9d4edd) - Accents, hover states
- **Cyber Yellow** (#ffbe0b) - Warnings, announcements
- **Cyber Green** (#06ffa5) - Success states, online indicators

**Design Features:**
- Monospace font (Courier New) for terminal aesthetic
- Subtle grid background for depth
- Neon glow effects on interactive elements
- Dark backgrounds (#0a0e27) to reduce eye strain
- High contrast text for readability

### Interface Layout

```
┌────────────────────────────────────────────────────────┐
│  📦 EmergencyBox - Offline Communication & File Sharing │
│  🟢 42 users connected                                  │
├─────────────────────┬──────────────────────────────────┤
│   GROUP CHAT        │      FILE SHARING                │
│                     │                                  │
│  [Messages...]      │  Upload File: [Browse...]        │
│  User1: Hello       │  Category: [Emergency ▼]         │
│  User2: Copy that   │  [Upload Button]                 │
│  🔴 URGENT: Help!   │                                  │
│                     │  📁 Emergency/                   │
│  [Username: ____]   │    map.pdf (2.3 MB)             │
│  [Message: _____]   │    contacts.xlsx (45 KB)        │
│  ☑️ Priority        │  📁 Media/                       │
│  📎 Link File       │    photo1.jpg (1.2 MB)          │
│  [Send]             │  📁 Documents/                   │
│                     │    procedures.pdf (850 KB)      │
└─────────────────────┴──────────────────────────────────┘
```

### Responsive Design

- **Desktop** (1200px+) - Two-column layout, full features
- **Tablet** (768px-1199px) - Stacked layout, touch-optimized
- **Mobile** (320px-767px) - Single column, simplified controls

### Accessibility Features

- Semantic HTML5 markup
- ARIA labels on interactive elements
- Keyboard navigation support
- High contrast color scheme
- Scalable text (respects browser zoom)

### Screenshots

> Screenshots showing the EmergencyBox interface in action:

**Main Interface:**
- Split-panel view with chat on left, files on right
- Cyberpunk theme with cyan/pink accent colors
- Status bar showing online users
- Real-time message updates

**File Upload:**
- Drag-and-drop zone
- Progress bar with percentage and speed
- Category selection dropdown
- Custom folder creation

**Priority Messages:**
- Red/pink highlighted urgent messages
- Visual priority flag icon
- Stands out in chat stream

**Admin Panel:**
- Announcement banner controls
- System statistics
- Chat moderation tools
- File management interface

---

## Documentation

Comprehensive documentation is available in the repository:

| Document | Status | Description |
|----------|--------|-------------|
| [INSTALLATION.md](docs/INSTALLATION.md) | ✅ Complete | Complete installation guide for DD-WRT and Asuswrt-Merlin |
| [QUICK_START.md](docs/QUICK_START.md) | ✅ Complete | Fast reference for experienced users |
| [USAGE.md](docs/USAGE.md) | ✅ Complete | End-user guide for chat and file sharing |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | ✅ Complete | Developer documentation for customization |
| [PHP_COMPATIBILITY.md](docs/PHP_COMPATIBILITY.md) | ✅ Complete | Troubleshooting PHP installation issues |
| **[ATAK.md](ATAK.md)** | **✅ Complete** | **ATAK-style tactical mapping specification and roadmap** |
| **[COMPETITION.md](COMPETITION.md)** | **✅ Complete** | **Competitive analysis vs POSM, FreeTAKServer, PirateBox, etc.** |

### Planned Documentation

| Document | Status | Description |
|----------|--------|-------------|
| DEPLOYMENT.md | 🎯 Planned | Advanced deployment scenarios, multi-router mesh |
| TROUBLESHOOTING.md | 🎯 Planned | Common issues and solutions |
| FIELD_GUIDE.md | 🎯 Planned | Quick reference card for disaster deployment |

---

## Contributing

Contributions are welcome! EmergencyBox is designed for humanitarian use, and we appreciate help improving its reliability and features.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Contribution Guidelines

- **Code Style** - Follow existing PHP and JavaScript conventions
- **Testing** - Test on actual hardware (ASUS RT-AC68U preferred)
- **Documentation** - Update relevant docs with your changes
- **Humanitarian Focus** - Keep emergency use cases in mind
- **Offline-First** - No external dependencies or internet requirements

### Areas for Contribution

**High Priority:**
- [ ] Automated testing framework
- [ ] Image thumbnail generation
- [ ] Multi-language support (i18n)
- [ ] Message search functionality
- [ ] Export chat history feature

**Medium Priority:**
- [ ] User nickname system (optional)
- [ ] Multiple chat rooms
- [ ] File preview modal
- [ ] Upload resumption on disconnect
- [ ] Admin authentication layer

**Low Priority:**
- [ ] Message editing/deletion
- [ ] Emoji picker
- [ ] Dark/light theme toggle
- [ ] Voice message upload
- [ ] QR code for quick WiFi sharing

### Testing Checklist

Before submitting a PR, verify:

- [ ] Works on ASUS RT-AC68U with DD-WRT
- [ ] No external dependencies introduced
- [ ] Upload/download tested with 100MB+ files
- [ ] Multi-user concurrent access tested
- [ ] Database migrations (if applicable) tested
- [ ] No PHP errors in lighttpd logs
- [ ] Responsive design verified on mobile
- [ ] Documentation updated

---

## License

MIT License

Copyright (c) 2024 EmergencyBox Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Humanitarian Use

EmergencyBox is specifically designed for humanitarian purposes including:
- Disaster relief operations
- Emergency response coordination
- Community resilience in remote areas
- Crisis communication scenarios

Organizations using EmergencyBox for humanitarian purposes are encouraged to share their experiences and contribute improvements back to the project.

---

## Acknowledgments

**Built with consideration for:**
- Disaster relief workers worldwide
- Emergency first responders
- Remote communities without internet access
- Humanitarian organizations (Red Cross, FEMA, NGOs)

**Inspired by:**
- [PirateBox](https://piratebox.cc/) - Original offline file sharing concept (discontinued 2015)
- [LibraryBox](http://librarybox.us/) - Educational offline content delivery
- [POSM](https://github.com/posm/posm) - Portable OpenStreetMap for humanitarian field mapping
- [ATAK](https://www.civtak.org/) - Android Tactical Assault Kit for situational awareness
- [FreeTAKServer](https://github.com/FreeTAKTeam/FreeTakServer) - Open source TAK server
- DD-WRT Community - Firmware and support ecosystem

**Special Thanks:**
- ASUS for creating hackable, powerful routers
- DD-WRT developers for amazing firmware
- Entware maintainers for ARM package repository
- Open source community for tools and libraries

---

## Project Status & Roadmap

**Current Version:** 0.9 (Beta)
**Status:** ⚠️ Work in Progress - Hobby project by solo developer
**Last Updated:** January 2026

### What Works Now ✅
- Group chat with real-time updates
- File sharing (up to 5GB)
- SQLite database
- Admin panel (announcements, moderation)

### What I'm Working On 🎯
- **ATAK-style tactical mapping** - Offline maps with markers, routes, measurements
  - See [ATAK.md](ATAK.md) for full specification
- Deployment testing and bug fixes
- Documentation improvements

### Ideas for the Future 💡
*(No promises, just things I'd like to try)*
- Voice message recording
- Image thumbnails in file browser
- Message search
- Better performance optimizations

**Note:** This is a hobby project. I work on it when I have time. No fixed timeline or guarantees. If you want to help, contributions are welcome!

---

## Support

### Community Support

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and community help
- **DD-WRT Forums** - Router-specific technical support

**Note:** This is a hobby project by a solo developer. I'll help when I can, but response times vary. Community contributions are very welcome!

---

## FAQ

**Q: Can I use this on other routers?**
A: Possibly. Any DD-WRT router with 256MB+ RAM and ARM architecture should work, but only ASUS RT-AC68U is officially supported.

**Q: Why no HTTPS/encryption?**
A: Self-signed certificates cause browser warnings, confusing for non-technical users in emergencies. It's designed for isolated offline networks.

**Q: How many users can it support?**
A: 20-30 concurrent users comfortably, up to 50 tested. Performance depends on upload/download activity.

**Q: Can I access it from the internet?**
A: Not recommended. EmergencyBox is designed for local, offline use only.

**Q: How do I backup the data?**
A: Copy `/opt/share/data/emergencybox.db` and `/opt/share/www/uploads/` via SCP.

**Q: What happens if the router loses power?**
A: SQLite is ACID-compliant. Recent messages/files are preserved. Services auto-restart on boot.

**Q: Can I customize the look?**
A: Yes! Edit `/www/css/style.css` to change colors, fonts, layout. See [DEVELOPMENT.md](docs/DEVELOPMENT.md).

---

## Links

- **Project Homepage:** [GitHub Repository](https://github.com/yourusername/emergencybox)
- **Documentation:** [/docs](docs/)
- **Issue Tracker:** [GitHub Issues](https://github.com/yourusername/emergencybox/issues)
- **DD-WRT:** [https://dd-wrt.com](https://dd-wrt.com)
- **Entware:** [https://github.com/Entware/Entware](https://github.com/Entware/Entware)

---

<p align="center">
  <strong>Built for humanity, in times of crisis</strong><br>
  When the internet fails, EmergencyBox connects
</p>

<p align="center">
  <sub>Made with ❤️ for disaster relief workers worldwide</sub>
</p>
