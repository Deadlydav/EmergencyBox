// EmergencyBox - Frontend Application

class EmergencyBox {
    constructor() {
        this.linkedFile = null;
        this.files = [];
        this.pollInterval = 2000; // Poll every 2 seconds
        this.announcementPaused = false;
        this.lastUpdate = Date.now();
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadSavedUsername();
        this.loadMessages();
        this.loadFiles();
        this.loadAnnouncement();
        this.startPolling();
        this.startUpdateTimer();
    }

    loadSavedUsername() {
        const saved = localStorage.getItem('emergencybox_username');
        if (saved) {
            document.getElementById('username-input').value = saved;
        }
    }

    setupEventListeners() {
        // Chat functionality
        document.getElementById('send-btn').addEventListener('click', () => this.sendMessage());
        document.getElementById('chat-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) this.sendMessage();
        });
        document.getElementById('clear-chat-btn').addEventListener('click', () => this.clearChat());

        // File linking
        document.getElementById('attach-file-btn').addEventListener('click', () => this.openFileLinkModal());

        // File upload
        document.getElementById('upload-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.uploadFile();
        });

        document.getElementById('category-select').addEventListener('change', (e) => {
            const customGroup = document.getElementById('custom-folder-group');
            customGroup.style.display = e.target.value === 'custom' ? 'block' : 'none';
        });

        // File management
        document.getElementById('refresh-files-btn').addEventListener('click', () => this.loadFiles());
        document.getElementById('search-files').addEventListener('input', (e) => this.filterFiles(e.target.value));

        // Modal
        document.querySelector('.modal-close').addEventListener('click', () => this.closeFileLinkModal());
        document.getElementById('file-link-modal').addEventListener('click', (e) => {
            if (e.target.id === 'file-link-modal') this.closeFileLinkModal();
        });

        document.getElementById('modal-search').addEventListener('input', (e) => this.filterModalFiles(e.target.value));

        // Announcement controls
        document.getElementById('pause-announcement').addEventListener('click', () => this.toggleAnnouncementPause());
        document.getElementById('close-announcement').addEventListener('click', () => this.closeAnnouncement());
    }

    // Announcement Functions
    async loadAnnouncement() {
        try {
            const response = await fetch('api/get_announcement.php');
            const data = await response.json();

            if (data.success && data.announcement && data.announcement.message) {
                this.showAnnouncement(data.announcement.message);
            }
        } catch (error) {
            console.error('Error loading announcement:', error);
        }
    }

    showAnnouncement(message) {
        const announcementBar = document.getElementById('announcement-bar');
        const announcementText = document.getElementById('announcement-text');
        const announcementText2 = document.getElementById('announcement-text-2');
        const announcementText3 = document.getElementById('announcement-text-3');

        announcementText.textContent = message;
        announcementText2.textContent = message;
        announcementText3.textContent = message;
        announcementBar.style.display = 'block';
    }

    toggleAnnouncementPause() {
        const announcementBar = document.getElementById('announcement-bar');
        const pauseBtn = document.getElementById('pause-announcement');

        this.announcementPaused = !this.announcementPaused;

        if (this.announcementPaused) {
            announcementBar.classList.add('paused');
            pauseBtn.textContent = '';
        } else {
            announcementBar.classList.remove('paused');
            pauseBtn.textContent = '';
        }
    }

    closeAnnouncement() {
        const announcementBar = document.getElementById('announcement-bar');
        announcementBar.style.display = 'none';
    }

    // Chat Functions
    async sendMessage() {
        const input = document.getElementById('chat-input');
        const usernameInput = document.getElementById('username-input');
        const message = input.value.trim();
        const username = usernameInput.value.trim();
        const isPriority = document.getElementById('priority-msg').checked;

        if (!message) return;

        // Save username to localStorage for next time
        if (username) {
            localStorage.setItem('emergencybox_username', username);
        }

        const data = {
            username: username || null,
            message: message,
            priority: isPriority ? 1 : 0,
            file_id: this.linkedFile ? this.linkedFile.id : null
        };

        try {
            const response = await fetch('api/send_message.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                input.value = '';
                document.getElementById('priority-msg').checked = false;
                this.linkedFile = null;
                this.updateLinkedFilePreview();
                this.loadMessages();
            } else {
                alert('Failed to send message: ' + result.error);
            }
        } catch (error) {
            console.error('Error sending message:', error);
            alert('Failed to send message');
        }
    }

    async loadMessages() {
        const timerEl = document.getElementById('update-timer');

        try {
            const response = await fetch('api/get_messages.php');
            const data = await response.json();

            if (data.success) {
                this.renderMessages(data.messages);
                this.lastUpdate = Date.now();
                this.updateTimerDisplay();

                // Flash effect only on successful update
                timerEl.classList.add('updating');
                setTimeout(() => {
                    timerEl.classList.remove('updating');
                }, 300);
            }
        } catch (error) {
            console.error('Error loading messages:', error);
        }
    }

    renderMessages(messages) {
        const container = document.getElementById('chat-messages');

        // Check if we're at the bottom before updating
        const isAtBottom = container.scrollHeight - container.scrollTop <= container.clientHeight + 50;

        // Store current message count
        const currentCount = container.children.length;
        const newCount = messages.length;

        // Only re-render if message count changed
        if (currentCount === newCount) {
            return;
        }

        container.innerHTML = '';

        // Find messages with images, track last 5
        const messagesWithImages = [];
        messages.forEach((msg, idx) => {
            if (msg.file_name && this.isImageFile(msg.file_name)) {
                messagesWithImages.push(idx);
            }
        });
        const lastFiveImages = messagesWithImages.slice(-5);

        messages.forEach((msg, idx) => {
            const messageEl = document.createElement('div');
            messageEl.className = 'message' + (msg.priority ? ' priority' : '');

            const header = document.createElement('div');
            header.className = 'message-header';

            const leftSide = document.createElement('div');
            leftSide.style.display = 'flex';
            leftSide.style.alignItems = 'center';
            leftSide.style.gap = '8px';

            if (msg.username) {
                const username = document.createElement('span');
                username.style.color = 'var(--cyber-cyan)';
                username.style.fontWeight = '600';
                username.textContent = msg.username;
                leftSide.appendChild(username);
            } else {
                const anon = document.createElement('span');
                anon.style.color = 'var(--text-secondary)';
                anon.style.fontStyle = 'italic';
                anon.textContent = 'Anonymous';
                leftSide.appendChild(anon);
            }

            const time = document.createElement('span');
            time.className = 'message-time';
            time.textContent = this.formatTime(msg.timestamp);
            leftSide.appendChild(time);

            header.appendChild(leftSide);

            if (msg.priority) {
                const badge = document.createElement('span');
                badge.className = 'priority-badge';
                badge.textContent = 'PRIORITY';
                header.appendChild(badge);
            }

            const content = document.createElement('div');
            content.className = 'message-content';
            content.textContent = msg.message;

            messageEl.appendChild(header);
            messageEl.appendChild(content);

            // Add file link if present
            if (msg.file_name) {
                const isImage = this.isImageFile(msg.file_name);
                const shouldShowPreview = isImage && lastFiveImages.includes(idx);

                if (shouldShowPreview) {
                    // Show image preview
                    const imgPreview = document.createElement('div');
                    imgPreview.className = 'image-preview';
                    const img = document.createElement('img');
                    img.src = msg.file_path;
                    img.alt = msg.file_name;
                    img.style.maxWidth = '300px';
                    img.style.maxHeight = '300px';
                    img.style.borderRadius = '4px';
                    img.style.marginTop = '8px';
                    img.style.cursor = 'pointer';
                    img.onclick = () => window.open(msg.file_path, '_blank');
                    imgPreview.appendChild(img);

                    const caption = document.createElement('div');
                    caption.style.marginTop = '4px';
                    caption.style.display = 'flex';
                    caption.style.alignItems = 'center';
                    caption.style.gap = '8px';
                    caption.style.fontSize = '0.85rem';
                    caption.style.maxWidth = '300px';

                    const fileInfo = document.createElement('span');
                    fileInfo.className = 'file-link';
                    fileInfo.style.flex = '1';
                    fileInfo.style.minWidth = '0';
                    fileInfo.style.overflow = 'hidden';
                    fileInfo.style.textOverflow = 'ellipsis';
                    fileInfo.style.whiteSpace = 'nowrap';
                    fileInfo.textContent = ` ${msg.file_name} (${this.formatFileSize(msg.file_size)})`;

                    const openBtn = document.createElement('button');
                    openBtn.className = 'btn-small';
                    openBtn.style.flexShrink = '0';
                    openBtn.textContent = 'Open';
                    openBtn.onclick = () => window.open(msg.file_path, '_blank');

                    const downloadBtn = document.createElement('button');
                    downloadBtn.className = 'btn-small';
                    downloadBtn.style.flexShrink = '0';
                    downloadBtn.textContent = 'Download';
                    downloadBtn.onclick = () => {
                        const a = document.createElement('a');
                        a.href = msg.file_path;
                        a.download = msg.file_name;
                        a.click();
                    };

                    caption.appendChild(fileInfo);
                    caption.appendChild(openBtn);
                    caption.appendChild(downloadBtn);
                    imgPreview.appendChild(caption);

                    messageEl.appendChild(imgPreview);
                } else {
                    // Show regular file link
                    const fileLink = document.createElement('a');
                    fileLink.className = 'file-link';
                    fileLink.href = msg.file_path;
                    fileLink.download = msg.file_name;
                    fileLink.innerHTML = ` ${msg.file_name} (${this.formatFileSize(msg.file_size)})`;
                    messageEl.appendChild(fileLink);
                }
            }

            container.appendChild(messageEl);
        });

        // Only auto-scroll if user was at bottom
        if (isAtBottom) {
            container.scrollTop = container.scrollHeight;
        }
    }

    isImageFile(filename) {
        const ext = filename.toLowerCase().split('.').pop();
        return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].includes(ext);
    }

    async clearChat() {
        if (!confirm('Are you sure you want to clear chat history?')) return;

        try {
            const response = await fetch('api/clear_chat.php', { method: 'POST' });
            const result = await response.json();

            if (result.success) {
                this.loadMessages();
            }
        } catch (error) {
            console.error('Error clearing chat:', error);
        }
    }

    // File Functions
    async uploadFile() {
        const form = document.getElementById('upload-form');
        const fileInput = document.getElementById('file-input');
        const categorySelect = document.getElementById('category-select');
        const customFolder = document.getElementById('custom-folder');
        const uploadBtn = document.getElementById('upload-btn');

        if (!fileInput.files.length) {
            alert('Please select a file');
            return;
        }

        const file = fileInput.files[0];
        const maxSize = 5 * 1024 * 1024 * 1024; // 5GB

        if (file.size > maxSize) {
            alert('File size exceeds 5GB limit');
            return;
        }

        const formData = new FormData();
        formData.append('file', file);
        formData.append('category', categorySelect.value);

        if (categorySelect.value === 'custom' && customFolder.value.trim()) {
            formData.append('custom_folder', customFolder.value.trim());
        }

        // Show progress
        const progressDiv = document.getElementById('upload-progress');
        const progressFill = document.getElementById('progress-fill');
        const progressText = document.getElementById('progress-text');

        progressDiv.style.display = 'block';
        uploadBtn.disabled = true;

        try {
            const xhr = new XMLHttpRequest();

            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percent = Math.round((e.loaded / e.total) * 100);
                    progressFill.style.width = percent + '%';
                    progressText.textContent = percent + '%';
                }
            });

            xhr.addEventListener('load', () => {
                if (xhr.status === 200) {
                    const result = JSON.parse(xhr.responseText);
                    if (result.success) {
                        alert('File uploaded successfully!');
                        form.reset();
                        progressDiv.style.display = 'none';
                        document.getElementById('custom-folder-group').style.display = 'none';
                        this.loadFiles();
                    } else {
                        alert('Upload failed: ' + result.error);
                    }
                } else {
                    alert('Upload failed: Server error');
                }
                uploadBtn.disabled = false;
            });

            xhr.addEventListener('error', () => {
                alert('Upload failed: Network error');
                uploadBtn.disabled = false;
                progressDiv.style.display = 'none';
            });

            xhr.open('POST', 'api/upload.php');
            xhr.send(formData);

        } catch (error) {
            console.error('Upload error:', error);
            alert('Upload failed');
            uploadBtn.disabled = false;
            progressDiv.style.display = 'none';
        }
    }

    async loadFiles() {
        const timerEl = document.getElementById('update-timer');

        try {
            const response = await fetch('api/get_files.php');
            const data = await response.json();

            if (data.success) {
                this.files = data.files;
                this.renderFiles(this.files);
                this.lastUpdate = Date.now();
                this.updateTimerDisplay();

                // Flash effect only on successful update
                timerEl.classList.add('updating');
                setTimeout(() => {
                    timerEl.classList.remove('updating');
                }, 300);
            }
        } catch (error) {
            console.error('Error loading files:', error);
        }
    }

    renderFiles(files) {
        const container = document.getElementById('file-list');
        container.innerHTML = '';

        // Group files by category
        const categories = {};
        files.forEach(file => {
            if (!categories[file.category]) {
                categories[file.category] = [];
            }
            categories[file.category].push(file);
        });

        // Render each category
        Object.keys(categories).sort().forEach(category => {
            const categoryDiv = document.createElement('div');
            categoryDiv.className = 'file-category';

            const header = document.createElement('div');
            header.className = 'category-header';
            header.innerHTML = ` ${category.toUpperCase()} (${categories[category].length})`;
            categoryDiv.appendChild(header);

            categories[category].forEach(file => {
                const fileItem = this.createFileItem(file);
                categoryDiv.appendChild(fileItem);
            });

            container.appendChild(categoryDiv);
        });
    }

    createFileItem(file) {
        const item = document.createElement('div');
        item.className = 'file-item';

        const info = document.createElement('div');
        info.className = 'file-info';

        const name = document.createElement('div');
        name.className = 'file-name';
        name.textContent = file.name;

        const meta = document.createElement('div');
        meta.className = 'file-meta';
        meta.textContent = `${this.formatFileSize(file.size)}  ${this.formatTime(file.uploaded)}`;

        info.appendChild(name);
        info.appendChild(meta);

        const actions = document.createElement('div');
        actions.className = 'file-actions';

        const downloadBtn = document.createElement('button');
        downloadBtn.className = 'btn-download';
        downloadBtn.textContent = 'Download';
        downloadBtn.onclick = () => window.location.href = file.path;

        const linkBtn = document.createElement('button');
        linkBtn.className = 'btn-link';
        linkBtn.textContent = 'Link';
        linkBtn.onclick = () => this.selectFileForLink(file);

        actions.appendChild(downloadBtn);
        actions.appendChild(linkBtn);

        item.appendChild(info);
        item.appendChild(actions);

        return item;
    }

    filterFiles(query) {
        const filtered = this.files.filter(file =>
            file.name.toLowerCase().includes(query.toLowerCase())
        );
        this.renderFiles(filtered);
    }

    // File Linking Functions
    openFileLinkModal() {
        document.getElementById('file-link-modal').style.display = 'flex';
        this.renderModalFiles(this.files);
    }

    closeFileLinkModal() {
        document.getElementById('file-link-modal').style.display = 'none';
        document.getElementById('modal-search').value = '';
    }

    renderModalFiles(files) {
        const container = document.getElementById('modal-file-list');
        container.innerHTML = '';

        files.forEach(file => {
            const item = document.createElement('div');
            item.className = 'modal-file-item';
            item.innerHTML = `
                <div class="file-name">${file.name}</div>
                <div class="file-meta">${file.category}  ${this.formatFileSize(file.size)}</div>
            `;
            item.onclick = () => {
                this.linkedFile = file;
                this.updateLinkedFilePreview();
                this.closeFileLinkModal();
            };
            container.appendChild(item);
        });
    }

    filterModalFiles(query) {
        const filtered = this.files.filter(file =>
            file.name.toLowerCase().includes(query.toLowerCase())
        );
        this.renderModalFiles(filtered);
    }

    selectFileForLink(file) {
        this.linkedFile = file;
        this.updateLinkedFilePreview();
    }

    updateLinkedFilePreview() {
        const preview = document.getElementById('linked-file-preview');

        if (this.linkedFile) {
            preview.style.display = 'flex';
            preview.innerHTML = `
                <span> ${this.linkedFile.name}</span>
                <button onclick="app.clearLinkedFile()" class="btn-small">Remove</button>
            `;
        } else {
            preview.style.display = 'none';
        }
    }

    clearLinkedFile() {
        this.linkedFile = null;
        this.updateLinkedFilePreview();
    }

    // Polling
    startPolling() {
        setInterval(() => {
            this.loadMessages();
            this.loadFiles();
            this.loadAnnouncement();
        }, this.pollInterval);
    }

    // Update Timer Functions
    startUpdateTimer() {
        setInterval(() => {
            this.updateTimerDisplay();
        }, 1000); // Update every second
    }

    updateTimerDisplay() {
        const timerEl = document.getElementById('update-timer');
        const elapsed = Math.floor((Date.now() - this.lastUpdate) / 1000);

        if (elapsed < 5) {
            timerEl.textContent = 'Updated just now';
        } else if (elapsed < 60) {
            timerEl.textContent = `Updated ${elapsed} sec ago`;
        } else if (elapsed < 3600) {
            const minutes = Math.floor(elapsed / 60);
            timerEl.textContent = `Updated ${minutes} min ago`;
        } else {
            const hours = Math.floor(elapsed / 3600);
            timerEl.textContent = `Updated ${hours} hr ago`;
        }
    }

    // Utility Functions
    formatTime(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diff = now - date;

        // If less than 24 hours, show time
        if (diff < 86400000) {
            return date.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        // Otherwise show date
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';

        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));

        return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
    }
}

// Initialize application
const app = new EmergencyBox();
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
