<?php
/** Coupon Management */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
if($_SERVER['REQUEST_METHOD']==='POST'){
    $act=$_POST['act']??'';
    if($act==='create'){
        $stmt=db()->prepare("INSERT INTO coupons(code,description,discount_type,discount_value,min_order_amount,max_uses,valid_from,valid_until,applicable_roles,created_by) VALUES(:code,:desc,:type,:val,:min,:max,:from,:until,:roles,:by)");
        $stmt->execute(['code'=>strtoupper(trim($_POST['code'])),'desc'=>$_POST['description'],'type'=>$_POST['discount_type'],'val'=>$_POST['discount_value'],'min'=>$_POST['min_order']?:0,'max'=>$_POST['max_uses']?:0,'from'=>$_POST['valid_from']?:date('Y-m-d'),'until'=>$_POST['valid_until']?:null,'roles'=>$_POST['roles'],'by'=>getAdmin()['id']]);
        header('Location:coupons.php?msg=Coupon+created');exit;
    }
    if($act==='toggle'){
        $stmt=db()->prepare("UPDATE coupons SET is_active = NOT is_active WHERE id=:id");
        $stmt->execute(['id'=>$_POST['coupon_id']]);
        header('Location:coupons.php?msg=Coupon+updated');exit;
    }
    if($act==='delete'){
        db()->prepare("DELETE FROM coupons WHERE id=:id")->execute(['id'=>$_POST['coupon_id']]);
        header('Location:coupons.php?msg=Coupon+deleted');exit;
    }
}
$coupons=db()->query("SELECT * FROM coupons ORDER BY created_at DESC")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="grid-2 mb-24">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-plus"></i> Create Coupon</h3></div><div class="card-body">
<form method="POST"><input type="hidden" name="act" value="create">
<div class="form-row"><div class="form-group"><label>Coupon Code</label><input name="code" class="form-control" required placeholder="e.g. ZIPPA50" style="text-transform:uppercase"></div>
<div class="form-group"><label>Discount Type</label><select name="discount_type" class="form-control"><option value="percentage">Percentage (%)</option><option value="fixed">Fixed (₦)</option></select></div></div>
<div class="form-row"><div class="form-group"><label>Discount Value</label><input name="discount_value" type="number" step="0.01" class="form-control" required placeholder="e.g. 10"></div>
<div class="form-group"><label>Min Order Amount (₦)</label><input name="min_order" type="number" step="0.01" class="form-control" value="0"></div></div>
<div class="form-group"><label>Description</label><input name="description" class="form-control" placeholder="e.g. 50% off first delivery"></div>
<div class="form-row"><div class="form-group"><label>Max Uses (0=unlimited)</label><input name="max_uses" type="number" class="form-control" value="0"></div>
<div class="form-group"><label>For Roles</label><select name="roles" class="form-control"><option value="all">All Users</option><option value="customer">Customers</option><option value="rider">Riders</option><option value="vendor">Vendors</option></select></div></div>
<div class="form-row"><div class="form-group"><label>Valid From</label><input name="valid_from" type="date" class="form-control" value="<?=date('Y-m-d')?>"></div>
<div class="form-group"><label>Valid Until</label><input name="valid_until" type="date" class="form-control"></div></div>
<button type="submit" class="btn btn-primary"><i class="fa-solid fa-ticket"></i> Create Coupon</button>
</form></div></div>
<div>
<div class="stat-card mb-16"><div class="stat-icon purple"><i class="fa-solid fa-ticket"></i></div><div class="stat-value"><?=count($coupons)?></div><div class="stat-label">Total Coupons</div></div>
<div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-toggle-on"></i></div><div class="stat-value"><?=count(array_filter($coupons,fn($c)=>$c['is_active']))?></div><div class="stat-label">Active</div></div>
</div></div>

<div class="card"><div class="card-header"><h3>All Coupons</h3></div>
<div class="table-wrap"><table><thead><tr><th>Code</th><th>Type</th><th>Value</th><th>Uses</th><th>Valid Until</th><th>Roles</th><th>Status</th><th>Actions</th></tr></thead><tbody>
<?php foreach($coupons as $c):?><tr>
<td class="fw-700" style="color:var(--brand)"><?=htmlspecialchars($c['code'])?></td>
<td><span class="badge badge-blue"><?=$c['discount_type']?></span></td>
<td class="fw-700"><?=$c['discount_type']==='percentage'?$c['discount_value'].'%':'₦'.number_format((float)$c['discount_value'],2)?></td>
<td><?=$c['used_count']?>/<?=$c['max_uses']?:'∞'?></td>
<td class="text-sm text-2"><?=$c['valid_until']?date('M d, Y',strtotime($c['valid_until'])):'No expiry'?></td>
<td><span class="badge badge-cyan"><?=$c['applicable_roles']?></span></td>
<td><span class="badge <?=$c['is_active']?'badge-green':'badge-red'?>"><?=$c['is_active']?'Active':'Disabled'?></span></td>
<td><div class="action-row">
<form method="POST" style="display:inline"><input type="hidden" name="act" value="toggle"><input type="hidden" name="coupon_id" value="<?=$c['id']?>"><button class="btn-icon" title="Toggle"><i class="fa-solid fa-power-off"></i></button></form>
<form method="POST" style="display:inline" onsubmit="return confirm('Delete?')"><input type="hidden" name="act" value="delete"><input type="hidden" name="coupon_id" value="<?=$c['id']?>"><button class="btn-icon danger" title="Delete"><i class="fa-solid fa-trash"></i></button></form>
</div></td></tr><?php endforeach;?>
<?php if(empty($coupons)):?><tr><td colspan="8" class="text-3" style="text-align:center;padding:40px">No coupons created yet</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
