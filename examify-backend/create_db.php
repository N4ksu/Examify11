<?php
try {
    $pdo = new PDO('mysql:host=127.0.0.1', 'root', '');
    $pdo->exec('CREATE DATABASE IF NOT EXISTS examify_db');
    echo "Database created successfully\n";
} catch (PDOException $e) {
    die($e->getMessage());
}
