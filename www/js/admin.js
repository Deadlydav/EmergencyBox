// EmergencyBox Admin Panel

class AdminPanel {
    constructor() {
        this.currentSection = 'announcements';
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupAnnouncementForm();
        this.loadCurrentAnnouncement();
        this.loadMessages();
        this.loadFiles();
        this.loadStats();
        this.startPolling();
    }

    setupNavigation() {
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
