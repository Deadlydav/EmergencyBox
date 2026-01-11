<?php
// EmergencyBox Configuration

// Database configuration
define('DB_PATH', __DIR__ . '/../../data/emergencybox.db');

// Upload configuration
define('UPLOAD_BASE_PATH', __DIR__ . '/../uploads/');
define('MAX_FILE_SIZE', 5 * 1024 * 1024 * 1024); // 5GB in bytes

// Initialize database
function initDatabase() {
    $db_dir = dirname(DB_PATH);
    if (!is_dir($db_dir)) {
        mkdir($db_dir, 0755, true);
    }

    $db = new SQLite3(DB_PATH);

    // Create messages table
    $db->exec("
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT DEFAULT NULL,
            message TEXT NOT NULL,
            priority INTEGER DEFAULT 0,
            file_id INTEGER DEFAULT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    // Create files table
    $db->exec("
        CREATE TABLE IF NOT EXISTS files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            category TEXT NOT NULL,
            size INTEGER NOT NULL,
            uploaded DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    // Create announcements table
    $db->exec("
        CREATE TABLE IF NOT EXISTS announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    return $db;
}

// Get database connection
function getDB() {
    return new SQLite3(DB_PATH);
}

// JSON response helper
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data);
