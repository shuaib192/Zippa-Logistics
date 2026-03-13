<?php
/** Analytics */
require_once __DIR__ . '/includes/header.php';
function n($v){return '₦'.number_format((float)$v,2);}

// Time-based stats
$today=date('Y-m-d');
$week=date('Y-m-d',strtotime('-7 days'));
$month=date('Y-m-d',strtotime('-30 days'));

$ordersToday=db()->query("SELECT COUNT(*) FROM orders WHERE DATE(created_at)='$today'")->fetchColumn();
$ordersWeek=db()->query("SELECT COUNT(*) FROM orders WHERE created_at >= '$week'")->fetchColumn();
$ordersMonth=db()->query("SELECT COUNT(*) FROM orders WHERE created_at >= '$month'")->fetchColumn();
$revToday=db()->query("SELECT COALESCE(SUM(zippa_commission),0) FROM orders WHERE DATE(created_at)='$today' AND payment_status='released'")->fetchColumn();
$revWeek=db()->query("SELECT COALESCE(SUM(zippa_commission),0) FROM orders WHERE created_at >= '$week' AND payment_status='released'")->fetchColumn();
$revMonth=db()->query("SELECT COALESCE(SUM(zippa_commission),0) FROM orders WHERE created_at >= '$month' AND payment_status='released'")->fetchColumn();
$newUsersToday=db()->query("SELECT COUNT(*) FROM users WHERE DATE(created_at)='$today'")->fetchColumn();
$newUsersWeek=db()->query("SELECT COUNT(*) FROM users WHERE created_at >= '$week'")->fetchColumn();
$newUsersMonth=db()->query("SELECT COUNT(*) FROM users WHERE created_at >= '$month'")->fetchColumn();

// Top riders
$topRiders=db()->query("SELECT u.full_name, COUNT(o.id) as deliveries, COALESCE(SUM(o.rider_earning),0) as earnings FROM orders o JOIN users u ON o.rider_id=u.id WHERE o.status IN ('delivered','completed') GROUP BY u.id,u.full_name ORDER BY deliveries DESC LIMIT 5")->fetchAll();

// Top vendors
$topVendors=db()->query("SELECT u.full_name, COUNT(o.id) as orders, COALESCE(SUM(o.total_fare),0) as revenue FROM orders o JOIN users u ON o.vendor_id=u.id WHERE o.vendor_id IS NOT NULL GROUP BY u.id,u.full_name ORDER BY orders DESC LIMIT 5")->fetchAll();

// Order status distribution
$statusDist=db()->query("SELECT status, COUNT(*) as cnt FROM orders GROUP BY status ORDER BY cnt DESC")->fetchAll();

// Daily orders last 7 days
$dailyOrders=db()->query("SELECT DATE(created_at) as day, COUNT(*) as cnt FROM orders WHERE created_at >= '$week' GROUP BY DATE(created_at) ORDER BY day")->fetchAll();
?>
<h3 class="mb-16" style="font-size:.9rem;color:var(--text-2)"><i class="fa-solid fa-calendar"></i> Performance Overview</h3>
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr)">
    <div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-box"></i></div><div class="stat-value"><?=$ordersToday?></div><div class="stat-label">Orders Today</div></div>
    <div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-box"></i></div><div class="stat-value"><?=$ordersWeek?></div><div class="stat-label">Orders (7 Days)</div></div>
    <div class="stat-card"><div class="stat-icon cyan"><i class="fa-solid fa-box"></i></div><div class="stat-value"><?=$ordersMonth?></div><div class="stat-label">Orders (30 Days)</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=n($revToday)?></div><div class="stat-label">Revenue Today</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=n($revWeek)?></div><div class="stat-label">Revenue (7 Days)</div></div>
    <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=n($revMonth)?></div><div class="stat-label">Revenue (30 Days)</div></div>
    <div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-user-plus"></i></div><div class="stat-value"><?=$newUsersToday?></div><div class="stat-label">New Users Today</div></div>
    <div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-user-plus"></i></div><div class="stat-value"><?=$newUsersWeek?></div><div class="stat-label">New Users (7 Days)</div></div>
    <div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-user-plus"></i></div><div class="stat-value"><?=$newUsersMonth?></div><div class="stat-label">New Users (30 Days)</div></div>
</div>

<div class="grid-2 mb-24">
    <div class="card"><div class="card-header"><h3><i class="fa-solid fa-trophy"></i> Top Riders</h3></div>
    <div class="table-wrap"><table><thead><tr><th>Rider</th><th>Deliveries</th><th>Earnings</th></tr></thead><tbody>
    <?php foreach($topRiders as $r):?><tr><td class="fw-700"><?=htmlspecialchars($r['full_name'])?></td><td><span class="badge badge-blue"><?=$r['deliveries']?></span></td><td class="fw-700"><?=n($r['earnings'])?></td></tr><?php endforeach;?>
    <?php if(empty($topRiders)):?><tr><td colspan="3" class="text-3" style="text-align:center;padding:24px">No data</td></tr><?php endif;?>
    </tbody></table></div></div>

    <div class="card"><div class="card-header"><h3><i class="fa-solid fa-store"></i> Top Vendors</h3></div>
    <div class="table-wrap"><table><thead><tr><th>Vendor</th><th>Orders</th><th>Revenue</th></tr></thead><tbody>
    <?php foreach($topVendors as $v):?><tr><td class="fw-700"><?=htmlspecialchars($v['full_name'])?></td><td><span class="badge badge-green"><?=$v['orders']?></span></td><td class="fw-700"><?=n($v['revenue'])?></td></tr><?php endforeach;?>
    <?php if(empty($topVendors)):?><tr><td colspan="3" class="text-3" style="text-align:center;padding:24px">No data</td></tr><?php endif;?>
    </tbody></table></div></div>
</div>

<div class="grid-2">
    <div class="card"><div class="card-header"><h3><i class="fa-solid fa-chart-bar"></i> Order Status Distribution</h3></div>
    <div class="card-body">
    <?php foreach($statusDist as $sd):?>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px">
        <span class="text-sm" style="width:90px"><?=ucfirst($sd['status'])?></span>
        <div style="flex:1;height:24px;background:var(--bg);border-radius:4px;overflow:hidden">
            <?php $pct=($totalOrders=array_sum(array_column($statusDist,'cnt')))?round($sd['cnt']/$totalOrders*100):0;?>
            <div style="height:100%;width:<?=$pct?>%;background:var(--brand);border-radius:4px;display:flex;align-items:center;padding-left:8px;font-size:.65rem;font-weight:700;color:#fff;min-width:24px"><?=$sd['cnt']?></div>
        </div>
        <span class="text-sm text-3"><?=$pct?>%</span>
    </div>
    <?php endforeach;?>
    </div></div>

    <div class="card"><div class="card-header"><h3><i class="fa-solid fa-chart-line"></i> Daily Orders (7 Days)</h3></div>
    <div class="card-body">
    <?php $max=max(array_column($dailyOrders,'cnt')?:['1']); foreach($dailyOrders as $d):?>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px">
        <span class="text-sm" style="width:70px"><?=date('M d',strtotime($d['day']))?></span>
        <div style="flex:1;height:24px;background:var(--bg);border-radius:4px;overflow:hidden">
            <div style="height:100%;width:<?=round($d['cnt']/$max*100)?>%;background:var(--green);border-radius:4px;display:flex;align-items:center;padding-left:8px;font-size:.65rem;font-weight:700;color:#fff;min-width:24px"><?=$d['cnt']?></div>
        </div>
    </div>
    <?php endforeach;?>
    <?php if(empty($dailyOrders)):?><p class="text-3 text-sm">No orders in the last 7 days</p><?php endif;?>
    </div></div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
