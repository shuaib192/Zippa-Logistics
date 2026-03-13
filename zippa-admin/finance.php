<?php
/** Finance */
require_once __DIR__ . '/includes/header.php';
function n4($v){return '₦'.number_format((float)$v,2);}
$msg=$_GET['msg']??'';
// Handle withdrawal actions
if($_SERVER['REQUEST_METHOD']==='POST'&&isset($_POST['w_action'])){
    $wid=$_POST['w_id'];$act=$_POST['w_action'];
    $status=$act==='approve'?'completed':'failed';
    db()->prepare("UPDATE withdrawals SET status=:s, updated_at=NOW() WHERE id=:id")->execute(['s'=>$status,'id'=>$wid]);
    header("Location:finance.php?msg=Withdrawal+$status");exit;
}
$rev=db()->query("SELECT COALESCE(SUM(zippa_commission),0) FROM orders WHERE payment_status='released'")->fetchColumn();
$vol=db()->query("SELECT COALESCE(SUM(total_fare),0) FROM orders WHERE payment_status IN ('paid','released','held')")->fetchColumn();
$wal=db()->query("SELECT COALESCE(SUM(balance),0) FROM wallets")->fetchColumn();
$esc=db()->query("SELECT COALESCE(SUM(pending_balance),0) FROM wallets")->fetchColumn();
$paid=db()->query("SELECT COALESCE(SUM(amount),0) FROM withdrawals WHERE status='completed'")->fetchColumn();
$pend=db()->query("SELECT COALESCE(SUM(amount),0) FROM withdrawals WHERE status='pending'")->fetchColumn();
$withdrawals=db()->query("SELECT w.*,u.full_name,u.role FROM withdrawals w JOIN users u ON w.user_id=u.id ORDER BY w.created_at DESC LIMIT 30")->fetchAll();
$txns=db()->query("SELECT wt.*,u.full_name FROM wallet_transactions wt JOIN wallets wl ON wt.wallet_id=wl.id JOIN users u ON wl.user_id=u.id ORDER BY wt.created_at DESC LIMIT 20")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr)">
<div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-naira-sign"></i></div><div class="stat-value"><?=n4($rev)?></div><div class="stat-label">Commission Revenue</div></div>
<div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-chart-line"></i></div><div class="stat-value"><?=n4($vol)?></div><div class="stat-label">Order Volume</div></div>
<div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-wallet"></i></div><div class="stat-value"><?=n4($wal)?></div><div class="stat-label">Wallet Balances</div></div>
<div class="stat-card"><div class="stat-icon yellow"><i class="fa-solid fa-lock"></i></div><div class="stat-value"><?=n4($esc)?></div><div class="stat-label">Escrow</div></div>
<div class="stat-card"><div class="stat-icon cyan"><i class="fa-solid fa-arrow-up"></i></div><div class="stat-value"><?=n4($paid)?></div><div class="stat-label">Total Paid Out</div></div>
<div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-hourglass-half"></i></div><div class="stat-value"><?=n4($pend)?></div><div class="stat-label">Pending Withdrawals</div></div>
</div>
<div class="card mb-24"><div class="card-header"><h3><i class="fa-solid fa-money-bill-transfer"></i> Withdrawal Requests</h3></div>
<div class="table-wrap"><table><thead><tr><th>User</th><th>Role</th><th>Amount</th><th>Bank</th><th>Account</th><th>Status</th><th>Date</th><th>Actions</th></tr></thead><tbody>
<?php foreach($withdrawals as $w):?><tr>
<td class="fw-700"><?=htmlspecialchars($w['full_name'])?></td>
<td><span class="badge badge-<?=['rider'=>'purple','vendor'=>'green','customer'=>'blue'][$w['role']]??'blue'?>"><?=$w['role']?></span></td>
<td class="fw-700"><?=n4($w['amount'])?></td><td><?=htmlspecialchars($w['bank_name']??'—')?></td><td><?=htmlspecialchars($w['account_number']??'—')?></td>
<td><span class="badge <?=['pending'=>'badge-yellow','completed'=>'badge-green','failed'=>'badge-red','processing'=>'badge-blue'][$w['status']]??'badge-yellow'?>"><?=$w['status']?></span></td>
<td class="text-sm text-2"><?=date('M d, H:i',strtotime($w['created_at']))?></td>
<td><?php if($w['status']==='pending'):?><div class="action-row">
<form method="POST" style="display:inline"><input type="hidden" name="w_id" value="<?=$w['id']?>"><button name="w_action" value="approve" class="btn btn-success btn-xs"><i class="fa-solid fa-check"></i></button></form>
<form method="POST" style="display:inline"><input type="hidden" name="w_id" value="<?=$w['id']?>"><button name="w_action" value="reject" class="btn btn-danger btn-xs"><i class="fa-solid fa-times"></i></button></form>
</div><?php else:?>—<?php endif;?></td>
</tr><?php endforeach;?>
<?php if(empty($withdrawals)):?><tr><td colspan="8" class="text-3" style="text-align:center;padding:40px">No withdrawals</td></tr><?php endif;?>
</tbody></table></div></div>
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-clock-rotate-left"></i> Recent Transactions</h3></div>
<div class="table-wrap"><table><thead><tr><th>User</th><th>Type</th><th>Amount</th><th>Description</th><th>Date</th></tr></thead><tbody>
<?php foreach($txns as $t):?><tr><td><?=htmlspecialchars($t['full_name'])?></td><td><span class="badge <?=$t['type']==='credit'?'badge-green':'badge-red'?>"><?=$t['type']?></span></td><td class="fw-700"><?=n4($t['amount'])?></td><td class="text-2 text-sm"><?=htmlspecialchars(substr($t['description']??'',0,50))?></td><td class="text-sm text-2"><?=date('M d, H:i',strtotime($t['created_at']))?></td></tr><?php endforeach;?>
<?php if(empty($txns)):?><tr><td colspan="5" class="text-3" style="text-align:center;padding:24px">No transactions</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
