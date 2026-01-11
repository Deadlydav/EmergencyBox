<?php
// Get files API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');

try {
    $db = getDB();

    $query = "
        SELECT
            id,
            name,
            path,
            category,
            size,
            uploaded
        FROM files
        ORDER BY uploaded DESC
    ";

    $result = $db->query($query);

    $files = [];
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        $files[] = $row;
    }

    jsonResponse([
        'success' => true,
        'files' => $files
    ]);

    $db->close();
} catch (Exception $e) {
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
