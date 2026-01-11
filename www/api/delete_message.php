<?php
// Delete single message API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    handleError('Method not allowed', 405);
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['id'])) {
    handleError('Invalid input');
}

$id = (int)$input['id'];

try {
    $db = getDB();

    $stmt = $db->prepare('DELETE FROM messages WHERE id = :id');
    $stmt->bindValue(':id', $id, SQLITE3_INTEGER);

    $result = $stmt->execute();

    if ($result) {
        jsonResponse(['success' => true]);
    } else {
        handleError('Failed to delete message', 500);
    }

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
