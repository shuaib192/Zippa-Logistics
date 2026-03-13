<?php
/**
 * Authentication Helper — Zippa Admin Panel
 * Session-based auth with bcrypt password verification
 */

session_start();

require_once __DIR__ . '/database.php';

function isLoggedIn(): bool {
    return isset($_SESSION['admin_id']) && !empty($_SESSION['admin_id']);
}

function requireLogin(): void {
    if (!isLoggedIn()) {
        header('Location: /Zippa%20Logistics/zippa-admin/login.php');
        exit;
    }
}

function getAdmin(): ?array {
    if (!isLoggedIn()) return null;
    return [
        'id'   => $_SESSION['admin_id'],
        'name' => $_SESSION['admin_name'],
        'email'=> $_SESSION['admin_email'],
    ];
}

function attemptLogin(string $email, string $password): bool {
    $stmt = db()->prepare("SELECT id, full_name, email, password_hash, role FROM users WHERE email = :email LIMIT 1");
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch();

    if (!$user) return false;
    if ($user['role'] !== 'admin') return false;
    if (!password_verify($password, $user['password_hash'])) return false;

    $_SESSION['admin_id']    = $user['id'];
    $_SESSION['admin_name']  = $user['full_name'];
    $_SESSION['admin_email'] = $user['email'];

    // Update last login
    db()->prepare("UPDATE users SET last_login_at = NOW() WHERE id = :id")->execute(['id' => $user['id']]);

    return true;
}

function logout(): void {
    session_destroy();
    header('Location: /Zippa%20Logistics/zippa-admin/login.php');
    exit;
}
