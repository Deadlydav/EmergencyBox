<?php
// File upload API

require_once 'config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    handleError('Method not allowed', 405);
}

// Check if file was uploaded
if (!isset($_FILES['file'])) {
    handleError('No file uploaded');
}

$file = $_FILES['file'];

// Check for upload errors
if ($file['error'] !== UPLOAD_ERR_OK) {
    $errorMessages = [
        UPLOAD_ERR_INI_SIZE => 'File exceeds upload_max_filesize',
        UPLOAD_ERR_FORM_SIZE => 'File exceeds MAX_FILE_SIZE',
        UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
        UPLOAD_ERR_NO_FILE => 'No file was uploaded',
        UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
        UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
        UPLOAD_ERR_EXTENSION => 'File upload stopped by extension'
    ];

    $errorMsg = isset($errorMessages[$file['error']])
        ? $errorMessages[$file['error']]
        : 'Unknown upload error';

    handleError($errorMsg);
}

// Validate file size
if ($file['size'] > MAX_FILE_SIZE) {
    handleError('File size exceeds 5GB limit');
}

// Get category
$category = isset($_POST['category']) ? $_POST['category'] : 'general';

// Handle custom folder
if ($category === 'custom') {
    if (!isset($_POST['custom_folder']) || empty(trim($_POST['custom_folder']))) {
        handleError('Custom folder name is required');
    }
    $category = preg_replace('/[^a-zA-Z0-9_-]/', '', trim($_POST['custom_folder']));
    if (empty($category)) {
        handleError('Invalid folder name');
    }
}

// Sanitize filename
$originalName = basename($file['name']);
$safeName = preg_replace('/[^a-zA-Z0-9._-]/', '_', $originalName);

// Create category directory if it doesn't exist
$categoryPath = UPLOAD_BASE_PATH . $category;
if (!is_dir($categoryPath)) {
    if (!mkdir($categoryPath, 0755, true)) {
        handleError('Failed to create category directory', 500);
    }
}

// Check if file already exists and append number if needed
$targetPath = $categoryPath . '/' . $safeName;
$counter = 1;
$nameWithoutExt = pathinfo($safeName, PATHINFO_FILENAME);
$extension = pathinfo($safeName, PATHINFO_EXTENSION);

while (file_exists($targetPath)) {
    $safeName = $nameWithoutExt . '_' . $counter . ($extension ? '.' . $extension : '');
    $targetPath = $categoryPath . '/' . $safeName;
    $counter++;
}

// Move uploaded file
if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    handleError('Failed to save file', 500);
}

// Save to database
try {
    $db = getDB();

    $relativePath = 'uploads/' . $category . '/' . $safeName;

    $stmt = $db->prepare('INSERT INTO files (name, path, category, size) VALUES (:name, :path, :category, :size)');
    $stmt->bindValue(':name', $originalName, SQLITE3_TEXT);
    $stmt->bindValue(':path', $relativePath, SQLITE3_TEXT);
    $stmt->bindValue(':category', $category, SQLITE3_TEXT);
    $stmt->bindValue(':size', $file['size'], SQLITE3_INTEGER);

    $result = $stmt->execute();

    if ($result) {
        jsonResponse([
            'success' => true,
            'file_id' => $db->lastInsertRowID(),
            'file_name' => $originalName,
            'file_path' => $relativePath,
            'file_size' => $file['size']
        ]);
    } else {
        // Clean up uploaded file
        unlink($targetPath);
        handleError('Failed to save file info to database', 500);
    }

    $db->close();
} catch (Exception $e) {
    // Clean up uploaded file
    if (file_exists($targetPath)) {
        unlink($targetPath);
    }
    handleError('Database error: ' . $e->getMessage(), 500);
}
?>
]0;root@DD-WRT: ~
[0;37m[[0;32m[01;32m[0;37m][[0;33mroot[0;37m@[0;96mDD-WRT[0;37m:[0;35m192.168.1.1[0;37m][[0;32m~[0;37m]
