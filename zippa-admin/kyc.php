<?php
/** KYC Review */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
$pending=db()->query("SELECT u.id,u.full_name,u.email,u.phone,u.role,u.created_at,kd.document_type,kd.document_number,kd.document_url,kd.created_at as sub_date FROM users u LEFT JOIN kyc_documents kd ON kd.user_id=u.id AND kd.status='pending' WHERE u.kyc_status='pending' ORDER BY u.created_at DESC")->fetchAll();
$reviewed=db()->query("SELECT u.id,u.full_name,u.email,u.role,u.kyc_status,u.updated_at FROM users u WHERE u.kyc_status IN ('verified','rejected') ORDER BY u.updated_at DESC LIMIT 15")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
<div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-clock"></i></div><div class="stat-value"><?=count($pending)?></div><div class="stat-label">Pending Reviews</div></div>
<div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-circle-check"></i></div><div class="stat-value"><?=db()->query("SELECT COUNT(*) FROM users WHERE kyc_status='verified'")->fetchColumn()?></div><div class="stat-label">Verified</div></div>
<div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-circle-xmark"></i></div><div class="stat-value"><?=db()->query("SELECT COUNT(*) FROM users WHERE kyc_status='rejected'")->fetchColumn()?></div><div class="stat-label">Rejected</div></div>
</div>
<div class="card mb-24"><div class="card-header"><h3><i class="fa-solid fa-shield-halved"></i> Pending Reviews</h3></div>
<?php if(empty($pending)):?><div class="empty-state"><i class="fa-solid fa-shield-check"></i><p>All caught up!</p></div>
<?php else:foreach($pending as $p):?>
<div style="padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:16px">
<div class="avatar-sm <?=$p['role']==='rider'?'purple':'green'?>"><?=strtoupper(substr($p['full_name'],0,1))?></div>
<div style="flex:1">
    <strong style="font-size:.85rem"><?=htmlspecialchars($p['full_name'])?></strong><br>
    <span class="text-sm text-3"><?=htmlspecialchars($p['email']?:$p['phone'])?> · <span class="badge badge-blue"><?=$p['role']?></span>
    <?php if($p['document_type']):?>
        · <span class="badge badge-yellow" style="font-size: 10px;"><?= strtoupper(str_replace('_', ' ', $p['document_type'])) ?></span>
    <?php endif;?>
    </span>
</div>
<div class="action-row">
<a href="user-view.php?id=<?=$p['id']?>" class="btn btn-ghost btn-sm"><i class="fa-solid fa-eye"></i> View</a>
<form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$p['id']?>"><input type="hidden" name="action" value="kyc_approve"><input type="hidden" name="redirect" value="kyc.php"><button class="btn btn-success btn-sm"><i class="fa-solid fa-check"></i> Approve</button></form>
<form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$p['id']?>"><input type="hidden" name="action" value="kyc_reject"><input type="hidden" name="redirect" value="kyc.php"><button class="btn btn-danger btn-sm"><i class="fa-solid fa-times"></i> Reject</button></form>
</div></div>
<?php endforeach;endif;?></div>

<div class="card"><div class="card-header"><h3>Recently Reviewed</h3></div>
<div class="table-wrap"><table><thead><tr><th>User</th><th>Role</th><th>Decision</th><th>Date</th><th>Actions</th></tr></thead><tbody>
<?php foreach($reviewed as $r):?><tr>
<td><div class="user-cell"><div class="avatar-sm blue"><?=strtoupper(substr($r['full_name'],0,1))?></div><div class="user-meta"><strong><?=htmlspecialchars($r['full_name'])?></strong><small><?=htmlspecialchars($r['email'])?></small></div></div></td>
<td><span class="badge badge-blue"><?=$r['role']?></span></td>
<td><span class="badge <?=$r['kyc_status']==='verified'?'badge-green':'badge-red'?>"><?=$r['kyc_status']?></span></td>
<td class="text-sm text-2"><?=date('M d, Y',strtotime($r['updated_at']))?></td>
<td><a href="user-view.php?id=<?=$r['id']?>" class="btn-icon"><i class="fa-solid fa-eye"></i></a></td>
</tr><?php endforeach;?>
<?php if(empty($reviewed)):?><tr><td colspan="5" class="text-3" style="text-align:center;padding:24px">None</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
