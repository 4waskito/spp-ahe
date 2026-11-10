<?php
/**
 * Simple file download script - bypasses CI4 completely
 */
$file = $_GET['f'] ?? '';

// Security: only allow files from exports directory, no path traversal
if (empty($file) || strpos($file, '..') !== false || strpos($file, '/') !== false || strpos($file, '\\') !== false) {
    http_response_code(400);
    echo 'Invalid file';
    exit;
}

$filepath = __DIR__ . '/exports/' . $file;

if (!file_exists($filepath)) {
    http_response_code(404);
    echo 'File not found';
    exit;
}

$ext = pathinfo($file, PATHINFO_EXTENSION);
$mime = match($ext) {
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'csv'  => 'text/csv',
    'pdf'  => 'application/pdf',
    default => 'application/octet-stream',
};

header('Content-Type: ' . $mime);
header('Content-Disposition: attachment; filename="' . $file . '"');
header('Content-Length: ' . filesize($filepath));
header('Cache-Control: no-cache');
readfile($filepath);

// Clean up after download
unlink($filepath);
exit;
