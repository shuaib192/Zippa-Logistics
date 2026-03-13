<?php
/** Order Detail View */
require_once __DIR__ . '/includes/header.php';
$id=$_GET['id']??'';if(!$id){header('Location:orders.php');exit;}
$o=db()->prepare("SELECT o.*,c.full_name as customer,c.phone as cust_phone,r.full_name as rider,r.phone as rider_phone,v.full_name as vendor_name FROM orders o LEFT JOIN users c ON o.customer_id=c.id LEFT JOIN users r ON o.rider_id=r.id LEFT JOIN users v ON o.vendor_id=v.id WHERE o.id=:id");
$o->execute(['id'=>$id]);$o=$o->fetch();if(!$o){header('Location:orders.php');exit;}
function n3($v){return '₦'.number_format((float)$v,2);}
// Handle status update
if($_SERVER['REQUEST_METHOD']==='POST'&&isset($_POST['new_status'])){
    $ns=$_POST['new_status'];
    $up="UPDATE orders SET status=:s, updated_at=NOW()";
    if($ns==='cancelled') $up.=", cancelled_at=NOW()";
    if($ns==='delivered') $up.=", delivered_at=NOW()";
    $up.=" WHERE id=:id";
    db()->prepare($up)->execute(['s'=>$ns,'id'=>$o['id']]);
    header("Location:order-view.php?id=$id&msg=Status+updated");exit;
}
$msg=$_GET['msg']??'';
function sb3($s){$m=['pending'=>'badge-yellow','accepted'=>'badge-blue','picked_up'=>'badge-cyan','in_transit'=>'badge-purple','delivered'=>'badge-green','completed'=>'badge-green','cancelled'=>'badge-red','paid'=>'badge-green','held'=>'badge-yellow','released'=>'badge-green','failed'=>'badge-red'];return '<span class="badge '.($m[$s]??'badge-yellow').'">'.htmlspecialchars($s).'</span>';}
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<a href="orders.php" class="btn btn-ghost btn-sm mb-16"><i class="fa-solid fa-arrow-left"></i> Back to Orders</a>

<div class="grid-2 mb-24">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-box"></i> Order #<?=htmlspecialchars($o['order_number'])?></h3><?=sb3($o['status'])?></div>
<div class="detail-grid">
<div class="detail-item"><label>Customer</label><span><?=htmlspecialchars($o['customer']??'N/A')?></span></div>
<div class="detail-item"><label>Customer Phone</label><span><?=htmlspecialchars($o['cust_phone']??'—')?></span></div>
<div class="detail-item"><label>Rider</label><span><?=htmlspecialchars($o['rider']??'Unassigned')?></span></div>
<div class="detail-item"><label>Rider Phone</label><span><?=htmlspecialchars($o['rider_phone']??'—')?></span></div>
<div class="detail-item"><label>Vendor</label><span><?=htmlspecialchars($o['vendor_name']??'N/A')?></span></div>
<div class="detail-item"><label>Package Type</label><span><?=htmlspecialchars($o['package_type']??'—')?></span></div>
<div class="detail-item full"><label>Pickup</label><span><?=htmlspecialchars($o['pickup_address'])?></span></div>
<div class="detail-item full"><label>Dropoff</label><span><?=htmlspecialchars($o['dropoff_address'])?></span></div>
<div class="detail-item"><label>Distance</label><span><?=$o['distance_km']??'—'?> km</span></div>
<div class="detail-item"><label>Payment Method</label><span><?=htmlspecialchars($o['payment_method']??'—')?></span></div>
</div></div>

<div>
<div class="stats-grid" style="grid-template-columns:1fr 1fr;margin-bottom:16px">
<div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=n3($o['total_fare'])?></div><div class="stat-label">Total Fare</div></div>
<div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-hand-holding-dollar"></i></div><div class="stat-value"><?=n3($o['rider_earning'])?></div><div class="stat-label">Rider Earning</div></div>
<div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-building-columns"></i></div><div class="stat-value"><?=n3($o['zippa_commission'])?></div><div class="stat-label">Commission</div></div>
<div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-receipt"></i></div><div class="stat-value"><?=sb3($o['payment_status'])?></div><div class="stat-label">Payment Status</div></div>
</div>
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-pen"></i> Update Status</h3></div><div class="card-body">
<form method="POST">
<div class="form-group"><select name="new_status" class="form-control">
<?php foreach(['pending','accepted','picked_up','in_transit','delivered','completed','cancelled'] as $s):?>
<option value="<?=$s?>" <?=$o['status']===$s?'selected':''?>><?=ucfirst(str_replace('_',' ',$s))?></option>
<?php endforeach;?></select></div>
<button type="submit" class="btn btn-primary"><i class="fa-solid fa-save"></i> Update</button>
</form></div></div>
</div></div>

<div class="card"><div class="card-header"><h3><i class="fa-solid fa-timeline"></i> Timeline</h3></div><div class="card-body">
<?php $events=[['Created',$o['created_at']],['Accepted',$o['accepted_at']],['Picked Up',$o['picked_up_at']],['Delivered',$o['delivered_at']],['Cancelled',$o['cancelled_at']]];
foreach($events as $e):if($e[1]):?>
<div style="display:flex;align-items:center;gap:12px;margin-bottom:10px"><span class="badge badge-green" style="width:80px;text-align:center"><?=$e[0]?></span><span class="text-sm text-2"><?=date('M d, Y H:i',strtotime($e[1]))?></span></div>
<?php endif;endforeach;?></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
