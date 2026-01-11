<?php
// Delete file API

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

    // Get file info first
    $stmt = $db->prepare('SELECT path FROM files WHERE id = :id');
    $stmt->bindValue(':id', $id, SQLITE3_INTEGER);
    $result = $stmt->execute();
    $file = $result->fetchArray(SQLITE3_ASSOC);

    if (!$file) {
        handleError('File not found', 404);
    }

    // Delete physical file
    $fullPath = __DIR__ . '/../' . $file['path'];
    if (file_exists($fullPath)) {
        unlink($fullPath);
    }

    // Delete from database
    $stmt = $db->prepare('DELETE FROM files WHERE id = :id');
    $stmt->bindValue(':id', $id, SQLITE3_INTEGER);
    $stmt->execute();

    jsonResponse(['success' => true]);

    $db->close();
} catch (Exception $e) {
    handleError('Error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
