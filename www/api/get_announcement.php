<?php
// Get current announcement API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');

try {
    $db = getDB();

    // Get the most recent active announcement
    $query = "
        SELECT id, message, created_at
        FROM announcements
        WHERE active = 1
        ORDER BY created_at DESC
        LIMIT 1
    ";

    $result = $db->query($query);
    $announcement = $result->fetchArray(SQLITE3_ASSOC);

    if ($announcement) {
        jsonResponse([
            'success' => true,
            'announcement' => $announcement
        ]);
    } else {
        jsonResponse([
            'success' => true,
            'announcement' => null
        ]);
    }

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
