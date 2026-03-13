<?php
/** Audit Log */
require_once __DIR__ . '/includes/header.php';
// Pull recent activity from audit_logs if available, otherwise show system events
$logs=[];
try{
    $logs=db()->query("SELECT a.*,u.full_name FROM audit_logs a LEFT JOIN users u ON a.user_id=u.id ORDER BY a.created_at DESC LIMIT 50")->fetchAll();
}catch(Exception $e){
    // table might not have all columns, try basic approach
}
// Also show recent state changes as pseudo-logs
$recentUsers=db()->query("SELECT 'user_update' as event, full_name as detail, updated_at as ts FROM users WHERE updated_at > created_at ORDER BY updated_at DESC LIMIT 10")->fetchAll();
$recentOrders=db()->query("SELECT 'order_status' as event, CONCAT('#',order_number,' → ',status) as detail, updated_at as ts FROM orders ORDER BY updated_at DESC LIMIT 10")->fetchAll();
$recentKYC=db()->query("SELECT 'kyc_review' as event, CONCAT(u.full_name,' → ',u.kyc_status) as detail, u.updated_at as ts FROM users u WHERE u.kyc_status IN ('verified','rejected') ORDER BY u.updated_at DESC LIMIT 10")->fetchAll();
$recentWith=db()->query("SELECT 'withdrawal' as event, CONCAT(u.full_name,' ₦',w.amount,' ',w.status) as detail, w.created_at as ts FROM withdrawals w JOIN users u ON w.user_id=u.id ORDER BY w.created_at DESC LIMIT 10")->fetchAll();
$all=array_merge($recentUsers,$recentOrders,$recentKYC,$recentWith);
usort($all,fn($a,$b)=>strtotime($b['ts'])-strtotime($a['ts']));
$all=array_slice($all,0,30);
$icons=['user_update'=>'fa-user-pen','order_status'=>'fa-box','kyc_review'=>'fa-shield-halved','withdrawal'=>'fa-money-bill-transfer'];
$colors=['user_update'=>'blue','order_status'=>'purple','kyc_review'=>'yellow','withdrawal'=>'green'];
?>
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-clipboard-list"></i> System Activity Log</h3><span class="text-sm text-3"><?=count($all)?> recent events</span></div>
<div class="table-wrap"><table><thead><tr><th>Event</th><th>Detail</th><th>Timestamp</th></tr></thead><tbody>
<?php foreach($all as $l):?><tr>
<td><span class="badge badge-<?=$colors[$l['event']]??'blue'?>"><i class="fa-solid <?=$icons[$l['event']]??'fa-circle-info'?>"></i> <?=str_replace('_',' ',ucfirst($l['event']))?></span></td>
<td><?=htmlspecialchars($l['detail'])?></td>
<td class="text-sm text-2"><?=date('M d, Y H:i',strtotime($l['ts']))?></td>
</tr><?php endforeach;?>
<?php if(empty($all)):?><tr><td colspan="3" class="text-3" style="text-align:center;padding:40px">No activity recorded</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
