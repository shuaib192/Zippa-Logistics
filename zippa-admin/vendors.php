<?php
/** Vendor Management */
require_once __DIR__ . '/includes/header.php';
$search=trim($_GET['search']??'');
$sql="SELECT u.id,u.full_name,u.email,u.phone,u.kyc_status,u.is_active,u.created_at,up.business_name,up.business_address,(SELECT COUNT(*) FROM products p WHERE p.vendor_id=u.id) as products,(SELECT COUNT(*) FROM orders o WHERE o.vendor_id=u.id) as orders,(SELECT COALESCE(SUM(o2.total_fare),0) FROM orders o2 WHERE o2.vendor_id=u.id AND o2.payment_status IN('paid','released','held')) as revenue FROM users u LEFT JOIN user_profiles up ON up.user_id=u.id WHERE u.role='vendor'";
$p=[];if($search){$sql.=" AND (u.full_name ILIKE :s OR u.email ILIKE :s OR up.business_name ILIKE :s)";$p['s']="%$search%";}
$sql.=" ORDER BY u.created_at DESC";$stmt=db()->prepare($sql);$stmt->execute($p);$vendors=$stmt->fetchAll();
function kB($s){$m=['verified'=>'badge-green','pending'=>'badge-yellow','rejected'=>'badge-red','unverified'=>'badge-cyan'];return '<span class="badge '.($m[$s]??'badge-cyan').'">'.$s.'</span>';}
?>
<div class="card"><form method="GET" class="filter-bar">
<input type="text" name="search" class="form-control" placeholder="Search vendors..." value="<?=htmlspecialchars($search)?>">
<button type="submit" class="btn btn-primary btn-sm"><i class="fa-solid fa-search"></i></button>
<?php if($search):?><a href="vendors.php" class="btn btn-ghost btn-sm">Clear</a><?php endif;?>
<span class="text-2 text-sm" style="margin-left:auto"><?=count($vendors)?> vendors</span></form>
<div class="table-wrap"><table><thead><tr><th>Vendor</th><th>Business</th><th>Products</th><th>Orders</th><th>Revenue</th><th>KYC</th><th>Status</th><th>Actions</th></tr></thead><tbody>
<?php foreach($vendors as $v):?><tr>
<td><div class="user-cell"><div class="avatar-sm green"><?=strtoupper(substr($v['full_name'],0,1))?></div><div class="user-meta"><strong><?=htmlspecialchars($v['full_name'])?></strong><small><?=htmlspecialchars($v['email']?:$v['phone'])?></small></div></div></td>
<td><?=htmlspecialchars($v['business_name']?:'—')?></td>
<td class="fw-700"><?=$v['products']?></td><td class="fw-700"><?=$v['orders']?></td>
<td class="fw-700">₦<?=number_format((float)$v['revenue'],2)?></td>
<td><?=kB($v['kyc_status'])?></td>
<td><span class="badge <?=$v['is_active']?'badge-green':'badge-red'?>"><?=$v['is_active']?'Active':'Banned'?></span></td>
<td><div class="action-row">
<a href="user-view.php?id=<?=$v['id']?>" class="btn-icon"><i class="fa-solid fa-eye"></i></a>
<?php if($v['is_active']):?>
<form method="POST" action="actions.php" style="display:inline" onsubmit="return confirm('Ban vendor?')"><input type="hidden" name="user_id" value="<?=$v['id']?>"><input type="hidden" name="action" value="ban"><input type="hidden" name="redirect" value="vendors.php"><button class="btn-icon"><i class="fa-solid fa-ban"></i></button></form>
<?php else:?>
<form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$v['id']?>"><input type="hidden" name="action" value="unban"><input type="hidden" name="redirect" value="vendors.php"><button class="btn-icon"><i class="fa-solid fa-check"></i></button></form>
<?php endif;?>
</div></td></tr><?php endforeach;?>
<?php if(empty($vendors)):?><tr><td colspan="8" class="text-3" style="text-align:center;padding:40px">No vendors</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
