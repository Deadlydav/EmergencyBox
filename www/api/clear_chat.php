<?php
// Clear chat history API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    handleError('Method not allowed', 405);
}

try {
    $db = getDB();

    $result = $db->exec('DELETE FROM messages');

    if ($result !== false) {
        jsonResponse(['success' => true]);
    } else {
        handleError('Failed to clear chat', 500);
    }

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
