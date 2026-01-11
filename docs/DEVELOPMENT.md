# EmergencyBox Development Guide

## Architecture

EmergencyBox uses a simple client-server architecture optimized for embedded systems:

```
┌─────────────────────────────────────────┐
│           Client (Browser)              │
│  ┌─────────────────────────────────┐   │
│  │  HTML/CSS (index.html)          │   │
│  │  JavaScript (app.js)            │   │
│  └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ HTTP/AJAX
               │
┌──────────────▼──────────────────────────┐
│      Web Server (lighttpd)              │
│  ┌─────────────────────────────────┐   │
│  │  FastCGI → PHP                  │   │
│  │  Static files                   │   │
│  └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Backend (PHP APIs)              │
│  ┌─────────────────────────────────┐   │
│  │  send_message.php               │   │
│  │  get_messages.php               │   │
│  │  upload.php                     │   │
│  │  get_files.php                  │   │
│  └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Data Layer (SQLite3)               │
│  ┌─────────────────────────────────┐   │
│  │  messages table                 │   │
│  │  files table                    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Technology Stack

### Frontend
- **HTML5**: Semantic markup
- **CSS3**: Responsive grid layout, flexbox
- **Vanilla JavaScript**: No dependencies for maximum offline reliability
- **AJAX**: XMLHttpRequest for file uploads, Fetch API for other requests

### Backend
- **PHP 7.4+**: Server-side logic
- **SQLite3**: Embedded database
- **lighttpd**: Lightweight web server
- **FastCGI**: PHP execution

## Project Structure

```
emergencybox/
├── www/                          # Web root
│   ├── index.html               # Main interface
│   ├── css/
│   │   └── style.css            # All styles
│   ├── js/
│   │   └── app.js               # Frontend application
│   ├── api/                     # PHP backend
│   │   ├── config.php           # Configuration & database init
│   │   ├── init_db.php          # Database setup script
│   │   ├── send_message.php     # POST message API
│   │   ├── get_messages.php     # GET messages API
│   │   ├── clear_chat.php       # DELETE messages API
│   │   ├── upload.php           # POST file upload API
│   │   └── get_files.php        # GET files list API
│   └── uploads/                 # File storage
│       ├── emergency/
│       ├── media/
│       ├── documents/
│       └── general/
├── config/                      # Server configuration
│   ├── php.ini                  # PHP settings
│   └── lighttpd.conf            # Web server config
├── docs/                        # Documentation
│   ├── INSTALLATION.md
│   ├── USAGE.md
│   └── DEVELOPMENT.md
└── README.md
```

## Database Schema

### messages table

```sql
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT NOT NULL,
    priority INTEGER DEFAULT 0,      -- 0 = normal, 1 = priority
    file_id INTEGER DEFAULT NULL,    -- FK to files.id
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### files table

```sql
CREATE TABLE files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,              -- Original filename
    path TEXT NOT NULL,              -- Relative path from web root
    category TEXT NOT NULL,          -- Folder/category name
    size INTEGER NOT NULL,           -- File size in bytes
    uploaded DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

### Chat APIs

#### POST /api/send_message.php

Send a new message to the chat.

**Request:**
```json
{
    "message": "Emergency shelter at coordinates...",
    "priority": 1,
    "file_id": 42
}
```

**Response:**
```json
{
    "success": true,
    "message_id": 123
}
```

#### GET /api/get_messages.php

Retrieve all messages (latest 100).

**Response:**
```json
{
    "success": true,
    "messages": [
        {
            "id": 1,
            "message": "System online",
            "priority": 0,
            "timestamp": "2025-01-10 12:00:00",
            "file_id": null,
            "file_name": null,
            "file_path": null,
            "file_size": null
        }
    ]
}
```

#### POST /api/clear_chat.php

Clear all chat messages.

**Response:**
```json
{
    "success": true
}
```

### File APIs

#### POST /api/upload.php

Upload a file.

**Request:** `multipart/form-data`
- `file`: File data
- `category`: Category name (emergency, media, documents, general, custom)
- `custom_folder`: Required if category is "custom"

**Response:**
```json
{
    "success": true,
    "file_id": 42,
    "file_name": "evacuation_map.pdf",
    "file_path": "uploads/emergency/evacuation_map.pdf",
    "file_size": 2048576
}
```

#### GET /api/get_files.php

Get list of all files.

**Response:**
```json
{
    "success": true,
    "files": [
        {
            "id": 1,
            "name": "evacuation_map.pdf",
            "path": "uploads/emergency/evacuation_map.pdf",
            "category": "emergency",
            "size": 2048576,
            "uploaded": "2025-01-10 12:00:00"
        }
    ]
}
```

## Frontend Architecture

### Main Class: EmergencyBox

Located in `www/js/app.js`, this class manages all frontend functionality.

**Key Methods:**

- `init()`: Initialize application and event listeners
- `sendMessage()`: Send chat message via API
- `loadMessages()`: Fetch and render messages
- `uploadFile()`: Handle file upload with progress tracking
- `loadFiles()`: Fetch and render file list
- `openFileLinkModal()`: Show file selection modal
- `startPolling()`: Auto-refresh messages and files every 2 seconds

### Polling Strategy

The app uses simple polling instead of WebSockets for maximum compatibility:

```javascript
startPolling() {
    setInterval(() => {
        this.loadMessages();
        this.loadFiles();
    }, 2000); // Every 2 seconds
}
```

**Why polling?**
- Simpler implementation
- No WebSocket server needed
- Works on all browsers
- Minimal server load with SQLite

## Customization

### Adding New File Categories

1. **Create folder:**
   ```bash
   mkdir /opt/share/www/uploads/your-category
   chmod 777 /opt/share/www/uploads/your-category
   ```

2. **Add to select dropdown** in `www/index.html`:
   ```html
   <option value="your-category">Your Category</option>
   ```

### Changing Message Limit

Edit `www/api/get_messages.php`:

```php
// Change LIMIT 100 to your desired number
$query = "SELECT ... LIMIT 200";
```

### Customizing UI Colors

Edit CSS variables in `www/css/style.css`:

```css
:root {
    --primary-color: #2563eb;     /* Change to your color */
    --danger-color: #dc2626;
    --success-color: #16a34a;
    /* ... */
}
```

### Adding File Type Restrictions

Edit `www/api/upload.php`:

```php
// After line where $file is defined, add:
$allowed_types = ['image/jpeg', 'image/png', 'application/pdf'];
$file_type = mime_content_type($file['tmp_name']);

if (!in_array($file_type, $allowed_types)) {
    handleError('File type not allowed');
}
```

### Changing Maximum File Size

1. **Update PHP config** (`config/php.ini`):
   ```ini
   upload_max_filesize = 10G
   post_max_size = 10G
   ```

2. **Update lighttpd config** (`config/lighttpd.conf`):
   ```
   server.max-request-size = 10737418240  # 10GB in bytes
   ```

3. **Update constant** in `www/api/config.php`:
   ```php
   define('MAX_FILE_SIZE', 10 * 1024 * 1024 * 1024); // 10GB
   ```

4. **Restart services**

## Testing Locally

You can test EmergencyBox on your development machine:

### Using PHP Built-in Server

```bash
cd www
php -S localhost:8000
```

Then:
1. Initialize database: `php api/init_db.php`
2. Open browser: `http://localhost:8000`

**Note:** File uploads >2GB may not work with built-in server.

### Using Docker

Create `Dockerfile`:

```dockerfile
FROM php:7.4-apache

RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev
RUN docker-php-ext-install pdo pdo_sqlite

COPY www/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
```

Build and run:
```bash
docker build -t emergencybox .
docker run -p 8080:80 emergencybox
```

## Performance Optimization

### Reduce Polling Frequency

If you have many concurrent users, increase the polling interval:

```javascript
// In www/js/app.js
this.pollInterval = 5000; // 5 seconds instead of 2
```

### Database Indexing

Add indexes for faster queries:

```sql
CREATE INDEX idx_messages_timestamp ON messages(timestamp);
CREATE INDEX idx_files_category ON files(category);
CREATE INDEX idx_files_uploaded ON files(uploaded);
```

### Chunked Upload

For very large files, implement chunked uploads to avoid timeouts:

1. Split file into chunks client-side
2. Upload chunks sequentially
3. Reassemble server-side

## Security Hardening

While EmergencyBox is designed for offline use, you can add security:

### Basic Authentication

Add to `lighttpd.conf`:

```
auth.backend = "plain"
auth.backend.plain.userfile = "/opt/etc/lighttpd.users"
auth.require = ( "/" => ("method" => "basic", "realm" => "EmergencyBox", "require" => "valid-user"))
```

### Rate Limiting

Add rate limiting to PHP APIs:

```php
// In config.php
function checkRateLimit($ip, $action, $limit = 10, $window = 60) {
    // Implement rate limiting logic
}
```

### Input Validation

All APIs already sanitize input, but you can add stricter validation:

```php
// Example: Restrict message content
if (preg_match('/[^a-zA-Z0-9\s\.,!?-]/', $message)) {
    handleError('Invalid characters in message');
}
```

## Extending Functionality

### Adding User Nicknames

1. Store nickname in localStorage:
   ```javascript
   const nickname = localStorage.getItem('nickname') || 'Anonymous';
   ```

2. Send with message:
   ```javascript
   const data = {
       message: message,
       nickname: nickname,
       // ...
   };
   ```

3. Update database schema:
   ```sql
   ALTER TABLE messages ADD COLUMN nickname TEXT DEFAULT 'Anonymous';
   ```

### Adding File Deletion

1. Create API endpoint `delete_file.php`
2. Add delete button to file items
3. Update database and filesystem

### Adding Image Previews

1. Generate thumbnails on upload
2. Store thumbnail path in database
3. Display thumbnails in file browser

## Debugging

### Enable PHP Error Display

Edit `config/php.ini`:

```ini
display_errors = On
error_reporting = E_ALL
```

### View Logs

```bash
# lighttpd errors
tail -f /opt/var/log/lighttpd/error.log

# PHP errors
tail -f /tmp/php_errors.log
```

### Browser Console

Open browser developer tools (F12) and check:
- Console for JavaScript errors
- Network tab for API request/response
- Application tab for localStorage

## Contributing

To contribute to EmergencyBox:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly on actual router hardware
4. Submit pull request with detailed description

## License

EmergencyBox is open source and free for humanitarian use.
