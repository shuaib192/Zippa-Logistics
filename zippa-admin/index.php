<?php
/** Dashboard — Live KPIs from PostgreSQL */
require_once __DIR__ . '/includes/header.php';
function naira($v){return '₦'.number_format((float)$v,2);}

$t = db()->query("SELECT COUNT(*) FROM users")->fetchColumn();
$cust = db()->query("SELECT COUNT(*) FROM users WHERE role='customer'")->fetchColumn();
$riders = db()->query("SELECT COUNT(*) FROM users WHERE role='rider'")->fetchColumn();
$vendors = db()->query("SELECT COUNT(*) FROM users WHERE role='vendor'")->fetchColumn();
$orders = db()->query("SELECT COUNT(*) FROM orders")->fetchColumn();
$pending = db()->query("SELECT COUNT(*) FROM orders WHERE status='pending'")->fetchColumn();
$active = db()->query("SELECT COUNT(*) FROM orders WHERE status IN ('accepted','picked_up','in_transit')")->fetchColumn();
$delivered = db()->query("SELECT COUNT(*) FROM orders WHERE status IN ('delivered','completed')")->fetchColumn();
$cancelled = db()->query("SELECT COUNT(*) FROM orders WHERE status='cancelled'")->fetchColumn();
$rev = db()->query("SELECT COALESCE(SUM(zippa_commission),0) FROM orders WHERE payment_status='released'")->fetchColumn();
$escrow = db()->query("SELECT COALESCE(SUM(pending_balance),0) FROM wallets")->fetchColumn();
$walBal = db()->query("SELECT COALESCE(SUM(balance),0) FROM wallets")->fetchColumn();
$pKYC = db()->query("SELECT COUNT(*) FROM users WHERE kyc_status='pending'")->fetchColumn();
$pWith = db()->query("SELECT COUNT(*) FROM withdrawals WHERE status='pending'")->fetchColumn();
$products = db()->query("SELECT COUNT(*) FROM products")->fetchColumn();
$disputes = db()->query("SELECT COUNT(*) FROM disputes WHERE status='open'")->fetchColumn();

$recent = db()->query("SELECT o.order_number,o.total_fare,o.status,o.created_at,u.full_name as customer FROM orders o LEFT JOIN users u ON o.customer_id=u.id ORDER BY o.created_at DESC LIMIT 8")->fetchAll();
function sBadge($s){$m=['pending'=>'badge-yellow','accepted'=>'badge-blue','picked_up'=>'badge-cyan','in_transit'=>'badge-purple','delivered'=>'badge-green','completed'=>'badge-green','cancelled'=>'badge-red'];return '<span class="badge '.($m[$s]??'badge-yellow').'">'.htmlspecialchars($s).'</span>';}
?>
<div class="stats-grid">
    <div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-users"></i></div><div class="stat-value"><?=$t?></div><div class="stat-label">Total Users</div></div>
    <div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-box"></i></div><div class="stat-value"><?=$orders?></div><div class="stat-label">Total Orders</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=naira($rev)?></div><div class="stat-label">Commission Revenue</div></div>
    <div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-clock"></i></div><div class="stat-value"><?=$pending?></div><div class="stat-label">Pending Orders</div></div>
    <div class="stat-card"><div class="stat-icon cyan"><i class="fa-solid fa-truck"></i></div><div class="stat-value"><?=$active?></div><div class="stat-label">Active Deliveries</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-circle-check"></i></div><div class="stat-value"><?=$delivered?></div><div class="stat-label">Completed</div></div>
    <div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-ban"></i></div><div class="stat-value"><?=$cancelled?></div><div class="stat-label">Cancelled</div></div>
    <div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-wallet"></i></div><div class="stat-value"><?=naira($walBal)?></div><div class="stat-label">Wallet Balances</div></div>
</div>
<div class="stats-grid" style="grid-template-columns:repeat(auto-fit,minmax(160px,1fr))">
    <div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-user"></i></div><div class="stat-value"><?=$cust?></div><div class="stat-label">Customers</div></div>
    <div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-motorcycle"></i></div><div class="stat-value"><?=$riders?></div><div class="stat-label">Riders</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-store"></i></div><div class="stat-value"><?=$vendors?></div><div class="stat-label">Vendors</div></div>
    <div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-shield-halved"></i></div><div class="stat-value"><?=$pKYC?></div><div class="stat-label">KYC Pending</div></div>
    <div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-money-bill-transfer"></i></div><div class="stat-value"><?=$pWith?></div><div class="stat-label">Withdrawals Pending</div></div>
    <div class="stat-card"><div class="stat-icon cyan"><i class="fa-solid fa-bag-shopping"></i></div><div class="stat-value"><?=$products?></div><div class="stat-label">Products</div></div>
    <div class="stat-card"><div class="stat-icon pink"><i class="fa-solid fa-lock"></i></div><div class="stat-value"><?=naira($escrow)?></div><div class="stat-label">Escrow Held</div></div>
    <div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-gavel"></i></div><div class="stat-value"><?=$disputes?></div><div class="stat-label">Open Disputes</div></div>
</div>
<div class="card">
    <div class="card-header"><h3><i class="fa-solid fa-clock-rotate-left"></i> Recent Orders</h3><a href="orders.php" class="btn btn-ghost btn-sm">View All</a></div>
    <div class="table-wrap"><table><thead><tr><th>Order #</th><th>Customer</th><th>Fare</th><th>Status</th><th>Date</th></tr></thead><tbody>
    <?php foreach($recent as $o):?>
    <tr><td style="font-weight:600;color:var(--brand)">#<?=htmlspecialchars($o['order_number'])?></td><td><?=htmlspecialchars($o['customer']??'N/A')?></td><td><?=naira($o['total_fare'])?></td><td><?=sBadge($o['status'])?></td><td class="text-2 text-sm"><?=date('M d, H:i',strtotime($o['created_at']))?></td></tr>
    <?php endforeach;?>
    <?php if(empty($recent)):?><tr><td colspan="5" class="text-3" style="text-align:center;padding:40px">No orders yet.</td></tr><?php endif;?>
    </tbody></table></div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
