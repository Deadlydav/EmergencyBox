<?php
// Get messages API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');

try {
    $db = getDB();

    // Get messages with file information
    $query = "
        SELECT
            m.id,
            m.username,
            m.message,
            m.priority,
            m.timestamp,
            f.id as file_id,
            f.name as file_name,
            f.path as file_path,
            f.size as file_size
        FROM messages m
        LEFT JOIN files f ON m.file_id = f.id
        ORDER BY m.timestamp DESC
        LIMIT 100
    ";

    $result = $db->query($query);

    $messages = [];
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        $messages[] = $row;
    }

    // Reverse to show oldest first
    $messages = array_reverse($messages);

    jsonResponse([
        'success' => true,
        'messages' => $messages
    ]);

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
