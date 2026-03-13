<?php
require_once __DIR__ . '/config/auth.php';
if (isLoggedIn()) { header('Location: index.php'); exit; }
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    if (attemptLogin($email, $password)) { header('Location: index.php'); exit; }
    else { $error = 'Invalid credentials or unauthorized access.'; }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zippa Admin — Sign In</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="/Zippa%20Logistics/zippa-admin/assets/css/style.css">
</head>
<body>
<div class="login-page">
    <div class="login-card">
        <div class="brand">
            <div class="brand-icon"><i class="fa-solid fa-bolt"></i></div>
            <h2>Zippa Admin</h2>
        </div>
        <p class="subtitle">Enter your credentials to access the command center</p>
        <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <form method="POST">
            <div class="form-group">
                <label>Email Address</label>
                <input type="email" name="email" class="form-control" required placeholder="admin@zippa.com" value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" class="form-control" required placeholder="••••••••">
            </div>
            <button type="submit" class="btn btn-primary">Sign In</button>
        </form>
    </div>
</div>
</body>
</html>
