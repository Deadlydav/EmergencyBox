<?php
// Set announcement API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    handleError('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['message'])) {
    handleError('Invalid input');
}

$message = trim($input['message']);

if (empty($message)) {
    handleError('Announcement message cannot be empty');
}

if (strlen($message) > 500) {
    handleError('Announcement too long (max 500 characters)');
}

try {
    $db = getDB();

    // Deactivate all previous announcements
    $db->exec('UPDATE announcements SET active = 0');

    // Insert new announcement
    $stmt = $db->prepare('INSERT INTO announcements (message, active) VALUES (:message, 1)');
    $stmt->bindValue(':message', $message, SQLITE3_TEXT);

    $result = $stmt->execute();

    if ($result) {
        jsonResponse([
            'success' => true,
            'announcement_id' => $db->lastInsertRowID()
        ]);
    } else {
        handleError('Failed to save announcement', 500);
    }

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
