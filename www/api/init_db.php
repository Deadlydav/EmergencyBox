<?php
// Database initialization script
// Run this once to set up the database

require_once 'config.php';

echo "Initializing EmergencyBox database...\n";

try {
    $db = initDatabase();

    echo "Database initialized successfully!\n";
    echo "Database location: " . DB_PATH . "\n";

    // Check tables
    $tables = [];
    $result = $db->query("SELECT name FROM sqlite_master WHERE type='table'");
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        $tables[] = $row['name'];
    }

    echo "Tables created: " . implode(', ', $tables) . "\n";

    $db->close();
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
