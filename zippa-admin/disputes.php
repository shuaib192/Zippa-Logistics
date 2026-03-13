<?php
/** Disputes Management */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
if($_SERVER['REQUEST_METHOD']==='POST'){
    $act=$_POST['act']??'';
    if($act==='create'){
        $stmt=db()->prepare("INSERT INTO disputes(order_id, reported_by, against_user, reason) VALUES(:oid,:by,:against,:reason)");
        $oid=$_POST['order_id']?:null;
        $stmt->execute(['oid'=>$oid,'by'=>$_POST['reported_by']??null,'against'=>$_POST['against_user']??null,'reason'=>$_POST['reason']]);
        header('Location:disputes.php?msg=Dispute+created');exit;
    }
    if($act==='resolve'||$act==='dismiss'){
        $status=$act==='resolve'?'resolved':'dismissed';
        $stmt=db()->prepare("UPDATE disputes SET status=:s, admin_notes=:n, resolved_by=:a, resolved_at=NOW() WHERE id=:id");
        $stmt->execute(['s'=>$status,'n'=>$_POST['notes']??'','a'=>getAdmin()['id'],'id'=>$_POST['dispute_id']]);
        header('Location:disputes.php?msg=Dispute+'.$status);exit;
    }
}
$open=db()->query("SELECT d.*,u1.full_name as reporter,u2.full_name as accused,o.order_number FROM disputes d LEFT JOIN users u1 ON d.reported_by=u1.id LEFT JOIN users u2 ON d.against_user=u2.id LEFT JOIN orders o ON d.order_id=o.id WHERE d.status IN ('open','investigating') ORDER BY d.created_at DESC")->fetchAll();
$closed=db()->query("SELECT d.*,u1.full_name as reporter,u2.full_name as accused,o.order_number,u3.full_name as resolver FROM disputes d LEFT JOIN users u1 ON d.reported_by=u1.id LEFT JOIN users u2 ON d.against_user=u2.id LEFT JOIN orders o ON d.order_id=o.id LEFT JOIN users u3 ON d.resolved_by=u3.id WHERE d.status IN ('resolved','dismissed') ORDER BY d.resolved_at DESC LIMIT 10")->fetchAll();
$allUsers=db()->query("SELECT id,full_name,role FROM users ORDER BY full_name")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="grid-2 mb-24">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-plus"></i> File New Dispute</h3></div><div class="card-body">
<form method="POST"><input type="hidden" name="act" value="create">
<div class="form-group"><label>Order # (optional)</label>
<select name="order_id" class="form-control"><option value="">— No specific order —</option>
<?php foreach(db()->query("SELECT id,order_number FROM orders ORDER BY created_at DESC LIMIT 50")->fetchAll() as $o):?><option value="<?=$o['id']?>">#<?=$o['order_number']?></option><?php endforeach;?></select></div>
<div class="form-row"><div class="form-group"><label>Reported By</label><select name="reported_by" class="form-control" required><?php foreach($allUsers as $au):?><option value="<?=$au['id']?>"><?=htmlspecialchars($au['full_name'])?> (<?=$au['role']?>)</option><?php endforeach;?></select></div>
<div class="form-group"><label>Against</label><select name="against_user" class="form-control" required><?php foreach($allUsers as $au):?><option value="<?=$au['id']?>"><?=htmlspecialchars($au['full_name'])?> (<?=$au['role']?>)</option><?php endforeach;?></select></div></div>
<div class="form-group"><label>Reason</label><textarea name="reason" class="form-control" required placeholder="Describe the dispute..."></textarea></div>
<button type="submit" class="btn btn-primary"><i class="fa-solid fa-gavel"></i> Create Dispute</button>
</form></div></div>
<div>
<div class="stat-card mb-16"><div class="stat-icon red"><i class="fa-solid fa-gavel"></i></div><div class="stat-value"><?=count($open)?></div><div class="stat-label">Open Disputes</div></div>
<div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-check-double"></i></div><div class="stat-value"><?=db()->query("SELECT COUNT(*) FROM disputes WHERE status='resolved'")->fetchColumn()?></div><div class="stat-label">Resolved</div></div>
</div></div>

<div class="card mb-24"><div class="card-header"><h3>Open Disputes</h3></div>
<?php foreach($open as $d):?>
<div style="padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:flex-start;gap:16px">
<div style="flex:1">
<p class="fw-700" style="margin-bottom:4px"><?=htmlspecialchars($d['reporter']??'Unknown')?> vs <?=htmlspecialchars($d['accused']??'Unknown')?> <?php if($d['order_number']):?><span class="tag">#<?=$d['order_number']?></span><?php endif;?></p>
<p class="text-sm text-2"><?=htmlspecialchars($d['reason'])?></p>
<p class="text-sm text-3"><?=date('M d, Y H:i',strtotime($d['created_at']))?></p>
</div>
<div style="display:flex;gap:6px">
<form method="POST"><input type="hidden" name="act" value="resolve"><input type="hidden" name="dispute_id" value="<?=$d['id']?>"><input type="hidden" name="notes" value="Resolved by admin"><button class="btn btn-success btn-sm"><i class="fa-solid fa-check"></i> Resolve</button></form>
<form method="POST"><input type="hidden" name="act" value="dismiss"><input type="hidden" name="dispute_id" value="<?=$d['id']?>"><input type="hidden" name="notes" value="Dismissed"><button class="btn btn-danger btn-sm"><i class="fa-solid fa-times"></i> Dismiss</button></form>
</div></div>
<?php endforeach;?>
<?php if(empty($open)):?><div class="empty-state"><i class="fa-solid fa-check-circle"></i><p>No open disputes</p></div><?php endif;?>
</div>

<div class="card"><div class="card-header"><h3>Resolved Disputes</h3></div>
<div class="table-wrap"><table><thead><tr><th>Parties</th><th>Order</th><th>Outcome</th><th>Resolved By</th><th>Date</th></tr></thead><tbody>
<?php foreach($closed as $d):?><tr><td><?=htmlspecialchars($d['reporter']??'')?> vs <?=htmlspecialchars($d['accused']??'')?></td><td><?=$d['order_number']?'#'.$d['order_number']:'—'?></td><td><span class="badge <?=$d['status']==='resolved'?'badge-green':'badge-red'?>"><?=$d['status']?></span></td><td><?=htmlspecialchars($d['resolver']??'—')?></td><td class="text-sm text-2"><?=$d['resolved_at']?date('M d',strtotime($d['resolved_at'])):''?></td></tr><?php endforeach;?>
<?php if(empty($closed)):?><tr><td colspan="5" class="text-3" style="text-align:center;padding:24px">None</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
