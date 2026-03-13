<?php
/** Orders Management */
require_once __DIR__ . '/includes/header.php';
$search=trim($_GET['search']??'');$status=$_GET['status']??'';
$sql="SELECT o.*,u.full_name as customer,r.full_name as rider,v.full_name as vendor_name FROM orders o LEFT JOIN users u ON o.customer_id=u.id LEFT JOIN users r ON o.rider_id=r.id LEFT JOIN users v ON o.vendor_id=v.id WHERE 1=1";
$p=[];
if($status){$sql.=" AND o.status=:s";$p['s']=$status;}
if($search){$sql.=" AND (o.order_number ILIKE :q OR u.full_name ILIKE :q)";$p['q']="%$search%";}
$sql.=" ORDER BY o.created_at DESC LIMIT 100";
$stmt=db()->prepare($sql);$stmt->execute($p);$orders=$stmt->fetchAll();
function n2($v){return '₦'.number_format((float)$v,2);}
function sb2($s){$m=['pending'=>'badge-yellow','accepted'=>'badge-blue','picked_up'=>'badge-cyan','in_transit'=>'badge-purple','delivered'=>'badge-green','completed'=>'badge-green','cancelled'=>'badge-red','paid'=>'badge-green','held'=>'badge-yellow','released'=>'badge-green','failed'=>'badge-red'];return '<span class="badge '.($m[$s]??'badge-yellow').'">'.htmlspecialchars($s).'</span>';}
?>
<div class="card"><form method="GET" class="filter-bar">
<input type="text" name="search" class="form-control" placeholder="Search by order # or customer..." value="<?=htmlspecialchars($search)?>" style="min-width:220px">
<select name="status" class="form-control" style="min-width:130px"><option value="">All Status</option>
<?php foreach(['pending','accepted','picked_up','in_transit','delivered','completed','cancelled'] as $s):?><option value="<?=$s?>" <?=$status===$s?'selected':''?>><?=ucfirst(str_replace('_',' ',$s))?></option><?php endforeach;?></select>
<button type="submit" class="btn btn-primary btn-sm"><i class="fa-solid fa-search"></i> Filter</button>
<?php if($search||$status):?><a href="orders.php" class="btn btn-ghost btn-sm">Clear</a><?php endif;?>
<span class="text-2 text-sm" style="margin-left:auto"><?=count($orders)?> orders</span></form>
<div class="table-wrap"><table><thead><tr><th>Order #</th><th>Customer</th><th>Rider</th><th>Vendor</th><th>Fare</th><th>Status</th><th>Payment</th><th>Date</th><th>Actions</th></tr></thead><tbody>
<?php foreach($orders as $o):?><tr>
<td style="font-weight:600;color:var(--brand)">#<?=htmlspecialchars($o['order_number'])?></td>
<td><?=htmlspecialchars($o['customer']??'N/A')?></td>
<td><?=$o['rider']?htmlspecialchars($o['rider']):'<span class="text-3">—</span>'?></td>
<td><?=$o['vendor_name']?htmlspecialchars($o['vendor_name']):'<span class="text-3">—</span>'?></td>
<td class="fw-700"><?=n2($o['total_fare'])?></td>
<td><?=sb2($o['status'])?></td>
<td><?=sb2($o['payment_status'])?></td>
<td class="text-2 text-sm"><?=date('M d, H:i',strtotime($o['created_at']))?></td>
<td><a href="order-view.php?id=<?=$o['id']?>" class="btn-icon" title="View"><i class="fa-solid fa-eye"></i></a></td>
</tr><?php endforeach;?>
<?php if(empty($orders)):?><tr><td colspan="9" class="text-3" style="text-align:center;padding:40px">No orders found</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
