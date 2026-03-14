<?php
require_once __DIR__ . '/../config/auth.php';
requireLogin();
$admin = getAdmin();
$currentPage = basename($_SERVER['PHP_SELF'], '.php');
$pageTitle = str_replace('-', ' ', $currentPage);
if ($pageTitle === 'index') $pageTitle = 'Dashboard';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zippa Admin — <?= ucfirst($pageTitle) ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="/Zippa%20Logistics/zippa-admin/assets/css/style.css">
</head>
<body>
<div class="app">
    <aside class="sidebar">
        <div class="sidebar-brand">
            <div class="brand-icon"><i class="fa-solid fa-bolt"></i></div>
            <h1>Zippa</h1>
        </div>
        <nav class="sidebar-nav">
            <span class="nav-section">Main</span>
            <a href="index.php" class="nav-link <?= $currentPage==='index'?'active':'' ?>">
                <i class="fa-solid fa-chart-pie"></i> Dashboard
            </a>
            <a href="analytics.php" class="nav-link <?= $currentPage==='analytics'?'active':'' ?>">
                <i class="fa-solid fa-chart-line"></i> Analytics
            </a>

            <span class="nav-section">Management</span>
            <a href="users.php" class="nav-link <?= $currentPage==='users'?'active':'' ?>">
                <i class="fa-solid fa-users"></i> Users
            </a>
            <a href="orders.php" class="nav-link <?= $currentPage==='orders'?'active':'' ?>">
                <i class="fa-solid fa-box"></i> Orders
            </a>
            <a href="vendors.php" class="nav-link <?= $currentPage==='vendors'?'active':'' ?>">
                <i class="fa-solid fa-store"></i> Vendors
            </a>
            <a href="products.php" class="nav-link <?= $currentPage==='products'?'active':'' ?>">
                <i class="fa-solid fa-bag-shopping"></i> Products
            </a>
            <a href="categories.php" class="nav-link <?= $currentPage==='categories'?'active':'' ?>">
                <i class="fa-solid fa-tags"></i> Categories
            </a>

            <span class="nav-section">Finance</span>
            <a href="finance.php" class="nav-link <?= $currentPage==='finance'?'active':'' ?>">
                <i class="fa-solid fa-wallet"></i> Finance
            </a>
            <a href="coupons.php" class="nav-link <?= $currentPage==='coupons'?'active':'' ?>">
                <i class="fa-solid fa-ticket"></i> Coupons
            </a>

            <span class="nav-section">Operations</span>
            <a href="kyc.php" class="nav-link <?= $currentPage==='kyc'?'active':'' ?>">
                <i class="fa-solid fa-shield-halved"></i> KYC Review
            </a>
            <a href="disputes.php" class="nav-link <?= $currentPage==='disputes'?'active':'' ?>">
                <i class="fa-solid fa-gavel"></i> Disputes
            </a>
            <a href="notifications.php" class="nav-link <?= $currentPage==='notifications'?'active':'' ?>">
                <i class="fa-solid fa-bell"></i> Notifications
            </a>
            <a href="mass-email.php" class="nav-link <?= $currentPage==='mass-email'?'active':'' ?>">
                <i class="fa-solid fa-envelope"></i> Mass Email
            </a>
            <a href="audit-log.php" class="nav-link <?= $currentPage==='audit-log'?'active':'' ?>">
                <i class="fa-solid fa-clipboard-list"></i> Audit Log
            </a>

            <div class="nav-divider"></div>
            <a href="app-settings.php" class="nav-link <?= $currentPage==='app-settings'?'active':'' ?>">
                <i class="fa-solid fa-money-bill-wave"></i> Service Prices
            </a>
            <a href="settings.php" class="nav-link <?= $currentPage==='settings'?'active':'' ?>">
                <i class="fa-solid fa-gear"></i> Settings
            </a>
        </nav>
        <div class="sidebar-footer">
            <div class="admin-pill">
                <div class="admin-avatar"><?= strtoupper(substr($admin['name'], 0, 1)) ?></div>
                <div class="admin-info">
                    <strong><?= htmlspecialchars($admin['name']) ?></strong>
                    <small>Administrator</small>
                </div>
                <a href="logout.php" class="logout-btn" title="Sign Out"><i class="fa-solid fa-right-from-bracket"></i></a>
            </div>
        </div>
    </aside>

    <main class="main">
        <header class="topbar">
            <div class="topbar-left">
                <h2 class="page-title"><?= ucfirst($pageTitle) ?></h2>
            </div>
            <div class="topbar-right">
                <a href="notifications.php" class="topbar-icon-btn"><i class="fa-solid fa-bell"></i></a>
                <span class="date-display"><?= date('M d, Y') ?></span>
            </div>
        </header>
        <div class="content">
