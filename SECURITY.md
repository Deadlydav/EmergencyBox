# Security Policy

## ⚠️ Important Disclaimer

**This is a hobby project by an independent developer, not a professional security-audited product.**

- 👤 **Solo Developer** - Built by one person for fun and learning
- 🎓 **Best Effort** - Security measures implemented based on available knowledge
- 🔧 **Community Driven** - If you find issues, please report them!
- ❌ **Not Enterprise Grade** - No professional security audit has been performed
- 💡 **Educational Purpose** - Use at your own risk, especially in critical scenarios

**I'm doing my best to make this secure, but I'm not a security expert or professional organization. Contributions and security reviews from the community are very welcome!**

---

## Project Security Stance

**EmergencyBox is designed for offline, isolated, trusted networks in emergency scenarios.**

This project **intentionally prioritizes accessibility over security** to ensure anyone can connect and communicate during disasters when authentication barriers could prevent life-saving coordination.

---

## ⚠️ Security by Design Choices

### What We DON'T Have (By Design)

| Missing Security Feature | Rationale |
|-------------------------|-----------|
| ❌ **User Authentication** | Emergency scenarios require instant access - no time for account creation |
| ❌ **Encryption (HTTPS)** | Self-signed certificates cause browser warnings, confusing for non-technical users |
| ❌ **Access Control Lists** | All users must be trusted in disaster relief contexts |
| ❌ **File Malware Scanning** | No antivirus available for ARM routers, manual review required |
| ❌ **Rate Limiting (strict)** | Basic flood protection only - emergency traffic can spike |
| ❌ **Audit Logging** | Minimal logs - focus on reliability over forensics |

**If you need these features, EmergencyBox may not be suitable for your use case.**

---

## ✅ Security Features We DO Have

### Input Validation & Sanitization

| Protection | Status | Implementation |
|------------|--------|----------------|
| **SQL Injection Prevention** | ✅ Implemented | Parameterized SQLite queries |
| **Path Traversal Protection** | ✅ Implemented | File upload directory restrictions |
| **XSS Prevention** | ✅ Implemented | Output escaping in JavaScript |
| **File Type Validation** | ✅ Implemented | MIME type checking |
| **Input Length Limits** | ✅ Implemented | Message (1000 chars), Username (50 chars) |
| **File Size Limits** | ✅ Implemented | Configurable (default 5GB) |
| **Filename Sanitization** | ✅ Implemented | Regex filtering, path normalization |

### Example: SQL Injection Prevention
```php
// ✅ GOOD - Parameterized query
$stmt = $db->prepare('INSERT INTO messages (message) VALUES (:message)');
$stmt->bindValue(':message', $message, SQLITE3_TEXT);
$stmt->execute();

// ❌ BAD - Never used in codebase
// $db->exec("INSERT INTO messages (message) VALUES ('$message')");
```

---

## 🔒 Deployment Security Recommendations

### For Trusted Emergency Networks (Default Use Case)

**Minimal security - maximum accessibility:**
- ✅ WiFi with simple password (shared verbally)
- ✅ Disable WAN access (LAN only)
- ✅ Physical router security (locked box)
- ✅ Change default router admin password
- ✅ Manual file review (check uploads periodically)

### For Less-Trusted Environments (If Needed)

**If deploying in non-emergency or semi-public scenarios:**

1. **Enable WPA2/WPA3 WiFi Encryption**
   ```bash
   # Set strong WiFi password via DD-WRT web interface
   # Wireless > Basic Settings > Security Mode: WPA2 Personal
   ```

2. **Disable WAN Access**
   ```bash
   # Security > Firewall > Block WAN Requests: Enable
   ```

3. **Change Router Admin Password**
   ```bash
   # Administration > Management > Router Password
   ```

4. **Add Basic Authentication (Custom Modification)**
   - Not included by default
   - See `docs/DEVELOPMENT.md` for implementation guide
   - Adds HTTP Basic Auth to lighttpd

5. **Enable HTTPS (Advanced)**
   - Generate self-signed certificate
   - Configure lighttpd SSL
   - Note: Causes browser warnings

6. **Implement Upload Restrictions**
   - Whitelist allowed file extensions
   - Reduce max file size
   - Add user quotas

---

## 🚨 Known Vulnerabilities & Risks

### HIGH RISK

#### 1. Malicious File Upload
**Risk Level:** 🔴 **HIGH**

**Description:** Users can upload any file type, including executables, scripts, or malware.

**Attack Scenario:**
- Attacker uploads `malware.exe` disguised as `document.pdf`
- Other users download and execute on their devices
- Network compromise, data theft, ransomware

**Mitigations:**
- ✅ Basic MIME type validation (easily bypassed)
- ⚠️ Manual file review by admin
- ⚠️ Trust-based network assumption
- ❌ No malware scanning (not available on router)

**Recommended Actions:**
- Deploy only in trusted networks (team members, vetted volunteers)
- Periodically review uploaded files via admin panel
- Educate users not to execute unknown files
- Consider whitelisting file extensions (config modification)

**Code Location:** `www/api/upload.php:14-84`

---

#### 2. Storage Exhaustion (DoS)
**Risk Level:** 🔴 **HIGH**

**Description:** Malicious user can fill USB storage with large files, causing system failure.

**Attack Scenario:**
- Attacker uploads multiple 5GB files
- USB drive fills completely
- Database writes fail, system becomes unusable

**Mitigations:**
- ✅ File size limit (5GB configurable)
- ⚠️ Admin can delete files
- ❌ No per-user quotas
- ❌ No automatic cleanup

**Recommended Actions:**
- Monitor disk space via admin panel
- Set lower file size limits for public deployments
- Implement user quotas (custom modification)
- Regular cleanup of old files

**Code Location:** `www/api/upload.php:40-42`, `config/php.ini:upload_max_filesize`

---

### MEDIUM RISK

#### 3. Chat Spam / Message Flooding
**Risk Level:** 🟡 **MEDIUM**

**Description:** User can spam chat with thousands of messages.

**Attack Scenario:**
- Attacker sends 1000+ messages rapidly
- Chat becomes unusable
- Database bloats
- Legitimate messages buried

**Mitigations:**
- ⚠️ Basic flood protection (client-side only)
- ✅ Admin can clear chat
- ❌ No server-side rate limiting

**Recommended Actions:**
- Monitor chat activity
- Use admin clear function if needed
- Add server-side rate limiting (custom modification)

**Code Location:** `www/api/send_message.php:10-61`

---

#### 4. Unauthorized Access to Router Admin
**Risk Level:** 🟡 **MEDIUM**

**Description:** Default DD-WRT credentials allow router takeover.

**Attack Scenario:**
- Attacker connects to WiFi
- Access `http://192.168.1.1` (DD-WRT admin)
- Login with default `root` / `admin`
- Take control of router, modify EmergencyBox

**Mitigations:**
- ⚠️ Deployment guide recommends password change
- ❌ Not enforced by EmergencyBox

**Recommended Actions:**
- **ALWAYS change default router password**
- Disable router admin access from WiFi (wired only)
- Use strong password for router admin

**Documentation:** `docs/INSTALLATION.md`, `DEPLOYMENT.md`

---

#### 5. Database Injection via File Metadata
**Risk Level:** 🟡 **MEDIUM**

**Description:** Malicious filenames could potentially exploit database.

**Attack Scenario:**
- Attacker uploads file named `'; DROP TABLE messages;--.jpg`
- If not properly sanitized, could execute SQL

**Mitigations:**
- ✅ Parameterized queries (prevents SQL injection)
- ✅ Filename sanitization (regex filter)
- ✅ Path normalization

**Status:** Protected, but defense-in-depth is important

**Code Location:** `www/api/upload.php:58-60`

---

### LOW RISK

#### 6. Cross-Site Scripting (XSS) via Chat Messages
**Risk Level:** 🟢 **LOW**

**Description:** JavaScript in chat messages could execute in other users' browsers.

**Attack Scenario:**
- Attacker sends message: `<script>alert('XSS')</script>`
- Other users' browsers execute the script
- Could steal session data, modify page

**Mitigations:**
- ✅ Output escaping in JavaScript
- ✅ Text content rendering (not innerHTML)
- ⚠️ Markdown/HTML not supported (reduces attack surface)

**Status:** Protected by output escaping

**Code Location:** `www/js/app.js` (message rendering)

---

#### 7. Information Disclosure via Error Messages
**Risk Level:** 🟢 **LOW**

**Description:** Detailed error messages expose system information.

**Attack Scenario:**
- Attacker triggers errors
- Error messages reveal PHP version, file paths, database structure
- Uses info for targeted attacks

**Mitigations:**
- ⚠️ Generic errors shown to users
- ⚠️ Detailed errors in server logs only
- ❌ PHP display_errors not always disabled

**Recommended Actions:**
- Ensure `display_errors = Off` in production
- Review error handling in all API endpoints

**Code Location:** `www/api/config.php`, all API files

---

#### 8. Directory Traversal via Custom Folder Names
**Risk Level:** 🟢 **LOW**

**Description:** Malicious folder names could access restricted paths.

**Attack Scenario:**
- Attacker creates custom folder: `../../etc/passwd`
- Could potentially write files outside upload directory

**Mitigations:**
- ✅ Strict regex filtering of folder names
- ✅ Path sanitization
- ✅ Only alphanumeric, dash, underscore allowed

**Status:** Protected by input validation

**Code Location:** `www/api/upload.php:52-56`

```php
// Sanitization example
$category = preg_replace('/[^a-zA-Z0-9_-]/', '', trim($_POST['custom_folder']));
```

---

## 🛡️ Security Best Practices for Deployment

### Pre-Deployment Checklist

- [ ] Change default router admin password
- [ ] Set WiFi password (share securely with team)
- [ ] Disable WAN access on router
- [ ] Verify `/opt/share/www/uploads/` permissions (755)
- [ ] Test file upload limits
- [ ] Review uploaded files directory structure
- [ ] Document WiFi credentials securely
- [ ] Physically secure router (locked box/room)

### During Operation

- [ ] Monitor disk space regularly
- [ ] Review uploaded files periodically
- [ ] Clear chat if spam occurs
- [ ] Backup database daily (`emergencybox.db`)
- [ ] Keep router in secure location
- [ ] Limit physical access to router

### Post-Deployment

- [ ] Securely wipe uploaded files (if sensitive)
- [ ] Backup critical data
- [ ] Factory reset router (if redeploying elsewhere)
- [ ] Document lessons learned
- [ ] Report security incidents to community

---

## 🐛 Reporting Security Vulnerabilities

### How to Report

**For security vulnerabilities, please open public GitHub issues.**

### What to Include

Please provide:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (if any)
- Your contact information (optional, for follow-up)

### Response Timeline

- **Acknowledgment:** Unknow
- **Initial Assessment:** Unknow
- **Fix Timeline:** If i can fix it

### Disclosure Policy

- We follow **responsible disclosure**
- Vulnerabilities will be patched before public disclosure
- Reporter will be credited (unless anonymous)

---

## 🔐 Security Hardening Guide

### Optional Modifications for Increased Security

#### 1. Add File Extension Whitelist

**File:** `www/api/upload.php`

```php
// Add after line 60
$allowed_extensions = ['jpg', 'jpeg', 'png', 'pdf', 'txt', 'doc', 'docx'];
$extension = strtolower(pathinfo($safeName, PATHINFO_EXTENSION));

if (!in_array($extension, $allowed_extensions)) {
    handleError('File type not allowed');
}
```

#### 2. Implement Rate Limiting

**File:** `www/api/send_message.php`

```php
// Add simple rate limiting
$ip = $_SERVER['REMOTE_ADDR'];
$rate_limit_file = '/tmp/rate_limit_' . md5($ip);

if (file_exists($rate_limit_file)) {
    $last_message_time = file_get_contents($rate_limit_file);
    if (time() - $last_message_time < 2) { // 2 second cooldown
        handleError('Please wait before sending another message');
    }
}

file_put_contents($rate_limit_file, time());
```

#### 3. Add HTTPS Support

**File:** `config/lighttpd.conf`

```conf
# Generate self-signed certificate first:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout /opt/etc/lighttpd/server.pem \
#   -out /opt/etc/lighttpd/server.pem

$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/opt/etc/lighttpd/server.pem"
}
```

#### 4. Add HTTP Basic Authentication

**File:** `config/lighttpd.conf`

```conf
# Install lighttpd-mod-auth
# opkg install lighttpd-mod-auth

server.modules += ( "mod_auth" )

auth.backend = "htpasswd"
auth.backend.htpasswd.userfile = "/opt/etc/lighttpd.user"

auth.require = ( "/" =>
    (
        "method"  => "basic",
        "realm"   => "EmergencyBox",
        "require" => "valid-user"
    )
)
```

#### 5. Disable PHP Error Display

**File:** `config/php.ini`

```ini
display_errors = Off
log_errors = On
error_log = /opt/var/log/php_errors.log
```

---

## 📚 Additional Resources

### Security Documentation

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PHP Security Best Practices](https://www.php.net/manual/en/security.php)
- [SQLite Security](https://www.sqlite.org/security.html)
- [DD-WRT Security Hardening](https://wiki.dd-wrt.com/wiki/index.php/Security)

### Related Projects

- [POSM Security](https://github.com/posm/posm/blob/master/SECURITY.md)
- [FreeTAKServer Security](https://github.com/FreeTAKTeam/FreeTakServer/security)

---

## 📝 Security Audit History

| Date | Auditor | Scope | Findings | Status |
|------|---------|-------|----------|--------|
| 2026-01-11 | Internal | Initial security review | 8 vulnerabilities documented | Open |
| - | - | - | - | - |

**Last Updated:** 2026-01-11
**Version:** 0.9 (Beta)

---

## ⚖️ Security vs Usability Trade-off

EmergencyBox **intentionally prioritizes usability over security** because:

1. **Lives are at stake** - Delays in communication can cost lives
2. **Non-technical users** - Aid workers, volunteers, victims may not understand security prompts
3. **Time-critical** - Must deploy in minutes, not hours
4. **Trusted networks** - Designed for vetted teams, not public internet
5. **Offline context** - No external attack surface when isolated

**If you need enterprise-grade security, consider:**
- [FreeTAKServer](https://github.com/FreeTAKTeam/FreeTakServer) - Full authentication, encryption
- [POSM](https://github.com/posm/posm) - Professional deployment with access controls
- Commercial solutions with security audits

**EmergencyBox is for emergencies.** Security takes a back seat to saving lives.

---

## 🙏 Acknowledgment

This project is maintained by an independent developer as a hobby project. While I've implemented security best practices to the best of my knowledge, I'm not a professional security researcher or part of a formal organization.

**I appreciate:**
- 🐛 Bug reports and vulnerability disclosures
- 🔍 Security reviews from experienced developers
- 💬 Constructive feedback and suggestions
- 🤝 Community contributions to improve security

**I cannot guarantee:**
- ⏱️ Specific response times (I have a day job!)
- 🛡️ Enterprise-level security
- 📞 24/7 support
- 💰 Bounty payments

**But I promise:**
- ✅ To take security reports seriously
- ✅ To fix issues when I can
- ✅ To be transparent about limitations
- ✅ To credit security researchers
- ✅ To learn and improve

---

**Remember: The biggest security risk in a disaster is not being able to communicate at all.**

**Use this software at your own risk. It's provided "as-is" for educational and humanitarian purposes.**
