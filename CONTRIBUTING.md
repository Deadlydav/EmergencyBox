# Contributing to EmergencyBox

Thank you for your interest in contributing to EmergencyBox! This project serves critical humanitarian needs, and your contributions can help people in emergency situations.

## 🚨 Humanitarian Mission

EmergencyBox provides offline communication infrastructure for disaster relief. When contributing, please consider:
- **Reliability** - Lives may depend on this system working correctly
- **Simplicity** - Emergency responders may not be technical experts
- **Resource Constraints** - Deployments often run on limited hardware
- **Offline-First** - Internet connectivity cannot be assumed

## 🎯 Priority Areas

### High Priority
- **Hardware Compatibility** - Support for additional DD-WRT routers
- **Performance Optimization** - Faster file uploads, lower memory usage
- **Stability Fixes** - Bug fixes, crash prevention, error handling
- **Documentation** - Deployment guides, troubleshooting, translations

### Medium Priority
- **Features** - User authentication (optional), file categories, search
- **UI Improvements** - Accessibility, mobile optimization, theming
- **Testing** - Unit tests, integration tests, field testing reports
- **Deployment Tools** - Automated setup scripts, monitoring tools

### Low Priority
- **Advanced Features** - Encryption, federation, advanced admin features
- **Code Cleanup** - Refactoring, modernization
- **Nice-to-Haves** - Aesthetic improvements, animations

## 🔧 Development Setup

### Prerequisites
```bash
# For local testing (Docker-based emulator)
docker --version
docker-compose --version

# For router deployment
python3 --version  # For router_telnet.py
# DD-WRT router with telnet/SSH access
```

### Local Development
```bash
# Clone repository
git clone https://github.com/yourusername/emergencybox.git
cd emergencybox

# Start Docker emulator
cd EMUL
docker-compose up -d

# Access at http://localhost:8080
```

### Router Testing
```bash
# Deploy to test router (see DEPLOYMENT.md)
./deploy.sh 192.168.1.1 root password

# Access at http://192.168.1.1:8080
```

## 📝 Contribution Process

### 1. **Fork & Branch**
```bash
# Fork on GitHub, then:
git clone https://github.com/YOURNAME/emergencybox.git
cd emergencybox
git checkout -b feature/your-feature-name
```

### 2. **Make Changes**
- Write clear, documented code
- Follow existing code style
- Test thoroughly (see Testing Checklist below)
- Update documentation if needed

### 3. **Commit**
```bash
# Use clear commit messages
git add .
git commit -m "Add feature: brief description

Detailed explanation of changes, why they were needed,
and how they solve the problem."
```

### 4. **Test**
Run the testing checklist (see below) before submitting.

### 5. **Pull Request**
- Push to your fork
- Create Pull Request on GitHub
- Fill out the PR template completely
- Link related issues
- Wait for review

## ✅ Testing Checklist

Before submitting a PR, verify:

### Functionality
- [ ] Feature works as intended
- [ ] No console errors (browser DevTools)
- [ ] No PHP errors (check logs)
- [ ] Works on test router (if applicable)

### Compatibility
- [ ] Tested on Chrome/Firefox/Safari
- [ ] Mobile responsive (if UI changes)
- [ ] Works with DD-WRT (if backend changes)
- [ ] PHP 8.x compatible

### Performance
- [ ] No significant performance degradation
- [ ] File uploads still work (test with 100MB+ file)
- [ ] Chat messages load quickly (test with 100+ messages)
- [ ] Low memory usage (check on router)

### Code Quality
- [ ] No hardcoded credentials or secrets
- [ ] SQL injection prevention maintained
- [ ] XSS prevention maintained
- [ ] Error handling present
- [ ] Comments added for complex logic

### Documentation
- [ ] README updated (if needed)
- [ ] DEPLOYMENT.md updated (if deployment changes)
- [ ] Code comments added
- [ ] CHANGELOG.md entry added

## 🐛 Bug Reports

When reporting bugs, include:

1. **Environment**
   - Router model and DD-WRT version
   - EmergencyBox version/commit
   - Browser and version
   - USB drive size and filesystem

2. **Steps to Reproduce**
   - Exact steps to trigger the bug
   - Expected vs actual behavior
   - Frequency (always/sometimes/rare)

3. **Logs & Screenshots**
   - Browser console errors (F12)
   - PHP error log (`/tmp/php_errors.log`)
   - lighttpd error log (`/opt/var/log/lighttpd/error.log`)
   - Screenshots if applicable

4. **Impact**
   - Severity (critical/major/minor)
   - Workaround available?

## 💡 Feature Requests

When requesting features:

1. **Use Case** - Explain the real-world scenario
2. **Current Problem** - What doesn't work now?
3. **Proposed Solution** - How should it work?
4. **Alternatives** - Other ways to solve it?
5. **Humanitarian Value** - How does this help emergency response?

## 📋 Code Style

### PHP
```php
// Use PSR-12 style
function getDB() {
    return new SQLite3(DB_PATH);
}

// Clear error handling
try {
    $result = doSomething();
} catch (Exception $e) {
    error_log("Error in doSomething: " . $e->getMessage());
    handleError('Operation failed', 500);
}
```

### JavaScript
```javascript
// Use ES6+, clear variable names
class EmergencyBox {
    async loadMessages() {
        try {
            const response = await fetch('api/get_messages.php');
            const data = await response.json();
            this.renderMessages(data.messages);
        } catch (error) {
            console.error('Error loading messages:', error);
            this.showError('Failed to load messages');
        }
    }
}
```

### SQL
```sql
-- Use prepared statements ALWAYS
$stmt = $db->prepare('SELECT * FROM messages WHERE id = :id');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
```

## 🌍 Real-World Testing

If you deploy EmergencyBox in a real emergency:

1. **Document Everything** - Screenshots, logs, lessons learned
2. **Report Back** - Create an issue with your experience
3. **Share Improvements** - Submit PRs for fixes you made
4. **Help Others** - Answer questions from other deployers

Your field experience is invaluable!

## 📬 Communication

- **GitHub Issues** - Bug reports, feature requests
- **Pull Requests** - Code contributions
- **Discussions** - Questions, ideas, show-and-tell
- **Email** - For security issues (see SECURITY.md when available)

## 🏆 Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- README.md (significant contributions)

## ⚖️ License

By contributing, you agree that your contributions will be licensed under the MIT License (see LICENSE file).

---

Thank you for helping make EmergencyBox better for those who need it most! 🙏
