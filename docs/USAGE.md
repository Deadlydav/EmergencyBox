# EmergencyBox User Guide

## Getting Started

### Connecting to EmergencyBox

1. **Connect to the WiFi network** broadcast by the router
   - Network name: (configured on your router)
   - Password: (configured on your router)

2. **Open a web browser** and navigate to:
   - Default: `http://192.168.1.1`
   - Or whatever IP your router is configured to use

3. You should see the **EmergencyBox interface**

## Using Group Chat

### Sending Messages

1. Type your message in the text input at the bottom
2. Click **Send** or press **Enter**
3. Messages appear immediately in the chat window

### Priority Messages

For urgent or important announcements:

1. Check the **Priority** checkbox before sending
2. Priority messages are highlighted with an orange background
3. They include a "PRIORITY" badge for easy identification

### Linking Files to Messages

To reference a file in your message:

1. Click the **📎 Link File** button
2. Search for the file you want to reference
3. Click on the file to select it
4. The file appears as a preview below the message input
5. Type your message and send
6. The message will include a clickable link to download the file

Example use case:
```
Message: "Emergency shelter locations updated"
Linked file: "shelter_map.pdf"
```

### Clearing Chat History

Click the **Clear** button in the chat header to remove all messages. This action cannot be undone.

## File Sharing

### Uploading Files

1. Click **Choose File** and select a file from your device
2. Select a **Category** from the dropdown:
   - **General**: Miscellaneous files
   - **Emergency**: Critical emergency documents, maps, procedures
   - **Media**: Photos, videos, audio files
   - **Documents**: Text documents, PDFs, spreadsheets
   - **Custom Folder**: Create your own category

3. If you selected "Custom Folder", enter a folder name (letters, numbers, hyphens, and underscores only)

4. Click **Upload File**

5. A progress bar shows upload status

6. Large files (up to 5GB) are supported but will take longer to upload

### Browsing Files

Files are organized by category in the file browser:

- **📁 CATEGORY NAME (count)** - Collapsible category headers
- Each file shows:
  - File name
  - File size
  - Upload timestamp

### Downloading Files

Click the **Download** button next to any file to download it to your device.

### Searching Files

Use the search box at the top of the file browser to filter files by name.

### Linking Files from File Browser

Click the **Link** button next to a file to select it for linking in your next chat message.

## Tips and Best Practices

### For Coordinators

1. **Use priority messages sparingly** - Only for truly urgent information
2. **Link reference files** - Attach maps, procedures, or contacts to relevant announcements
3. **Organize files by category** - Makes it easier for everyone to find what they need
4. **Use descriptive file names** - "evacuation_route_north_v2.pdf" is better than "map.pdf"

### For Users

1. **Check chat regularly** - Important updates may be posted
2. **Download important files** - Save them to your device for offline access
3. **Keep file names clear** - Help others understand what you're sharing
4. **Respect storage limits** - Delete unnecessary files to save space

### Storage Management

The system storage depends on the router's USB drive:

- Monitor available space
- Delete old or unnecessary files
- Compress large files before uploading if possible
- Use appropriate file formats (e.g., JPEG instead of RAW for photos)

## Supported File Types

EmergencyBox supports **all file types**, including:

- **Documents**: PDF, DOC, DOCX, TXT, XLS, XLSX, etc.
- **Images**: JPG, PNG, GIF, SVG, etc.
- **Videos**: MP4, AVI, MOV, etc.
- **Audio**: MP3, WAV, OGG, etc.
- **Archives**: ZIP, RAR, 7Z, TAR, GZ, etc.
- **Other**: Any file type up to 5GB

## Browser Compatibility

EmergencyBox works on:

- Chrome/Chromium
- Firefox
- Safari
- Edge
- Mobile browsers (iOS Safari, Chrome Mobile, etc.)

## Offline Usage

Once connected to the router's WiFi:

- No internet connection is required
- All features work completely offline
- Messages and files are stored locally on the router
- Multiple devices can connect simultaneously

## Limitations

### File Size
- Maximum file size: **5GB**
- Actual limit may be lower depending on router storage

### Concurrent Uploads
- Only one file upload per user at a time
- Multiple users can upload simultaneously

### Message Length
- Maximum message length: **1000 characters**

### Browser Requirements
- JavaScript must be enabled
- Cookies should be enabled for best experience

## Troubleshooting

### Can't Connect to EmergencyBox

1. Verify you're connected to the correct WiFi network
2. Try navigating to `http://192.168.1.1`
3. Check if router is powered on
4. Restart your device's WiFi connection

### Upload Failing

1. Check file size (must be under 5GB)
2. Ensure router has sufficient storage space
3. Try a smaller file first to test
4. Wait for current upload to complete before starting another

### Messages Not Appearing

1. Click the Refresh button
2. Check browser console for errors (F12)
3. Verify internet/network connectivity to router
4. Clear browser cache and reload

### Files Not Showing

1. Click **Refresh** in the file panel
2. Check if upload completed successfully
3. Verify the file was saved to correct category

## Emergency Scenarios

### Power Outage

If the router loses power:
- All data on the USB drive is preserved
- Messages and files remain intact
- System automatically restarts when power returns

### Adding Users

New users can connect anytime:
- Connect to WiFi network
- Navigate to router IP
- All previous messages and files are visible
- No account creation needed (anonymous system)

### Data Export

To backup or export data:
- Download individual files through the interface
- Administrator can backup the database via SSH
- See INSTALLATION.md for backup procedures

## Privacy and Security

### Anonymous System

- No user accounts or logins required
- No tracking of who sent messages
- All users have equal access

### Data Retention

- Messages persist until manually cleared
- Files remain until manually deleted
- No automatic cleanup

### Network Security

- Use WPA2 encryption on WiFi
- System only accessible via local network
- No internet connection required or used

## Support

For technical issues:
- Check the troubleshooting section
- Review logs (admin access required)
- Consult INSTALLATION.md for configuration
- GitHub: https://github.com/anthropics/claude-code/issues
