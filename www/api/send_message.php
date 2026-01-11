<?php
// Send message API

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
    handleError('Message cannot be empty');
}

if (strlen($message) > 1000) {
    handleError('Message too long (max 1000 characters)');
}

$username = isset($input['username']) && !empty(trim($input['username'])) ? trim($input['username']) : null;
if ($username && strlen($username) > 50) {
    handleError('Username too long (max 50 characters)');
}

$priority = isset($input['priority']) ? (int)$input['priority'] : 0;
$file_id = isset($input['file_id']) ? (int)$input['file_id'] : null;

try {
    $db = getDB();

    $stmt = $db->prepare('INSERT INTO messages (username, message, priority, file_id) VALUES (:username, :message, :priority, :file_id)');
    $stmt->bindValue(':username', $username, SQLITE3_TEXT);
    $stmt->bindValue(':message', $message, SQLITE3_TEXT);
    $stmt->bindValue(':priority', $priority, SQLITE3_INTEGER);
    $stmt->bindValue(':file_id', $file_id, SQLITE3_INTEGER);

    $result = $stmt->execute();

    if ($result) {
        jsonResponse([
            'success' => true,
            'message_id' => $db->lastInsertRowID()
        ]);
    } else {
        handleError('Failed to save message', 500);
    }

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
