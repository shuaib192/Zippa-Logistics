<?php
/** Notifications */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
if($_SERVER['REQUEST_METHOD']==='POST'&&isset($_POST['broadcast'])){
    $title=trim($_POST['title']??'');$body=trim($_POST['body']??'');$target=$_POST['target']??'all';
    if($title&&$body){
        $sql="SELECT id FROM users WHERE 1=1";
        if($target!=='all') $sql.=" AND role='".addslashes($target)."'";
        $users=db()->query($sql)->fetchAll();
        $stmt=db()->prepare("INSERT INTO notifications(user_id,title,body,type) VALUES(:uid,:t,:b,'broadcast')");
        foreach($users as $u) $stmt->execute(['uid'=>$u['id'],'t'=>$title,'b'=>$body]);
        header("Location:notifications.php?msg=Notification+sent+to+".count($users)."+users");exit;
    }
}
$total=db()->query("SELECT COUNT(*) FROM notifications")->fetchColumn();
$unread=db()->query("SELECT COUNT(*) FROM notifications WHERE is_read=false")->fetchColumn();
$recent=db()->query("SELECT n.*,u.full_name FROM notifications n JOIN users u ON n.user_id=u.id ORDER BY n.created_at DESC LIMIT 30")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="grid-2 mb-24"><div class="card"><div class="card-header"><h3><i class="fa-solid fa-bullhorn"></i> Send Push Notification</h3></div><div class="card-body">
<form method="POST"><div class="form-group"><label>Target</label><select name="target" class="form-control"><option value="all">All Users</option><option value="customer">Customers</option><option value="rider">Riders</option><option value="vendor">Vendors</option></select></div>
<div class="form-group"><label>Title</label><input name="title" class="form-control" required placeholder="Notification title"></div>
<div class="form-group"><label>Message</label><textarea name="body" class="form-control" required placeholder="Message body..."></textarea></div>
<button type="submit" name="broadcast" value="1" class="btn btn-primary"><i class="fa-solid fa-paper-plane"></i> Send</button></form></div></div>
<div><div class="stat-card mb-16"><div class="stat-icon blue"><i class="fa-solid fa-bell"></i></div><div class="stat-value"><?=$total?></div><div class="stat-label">Total Sent</div></div>
<div class="stat-card"><div class="stat-icon red"><i class="fa-solid fa-bell-slash"></i></div><div class="stat-value"><?=$unread?></div><div class="stat-label">Unread</div></div></div></div>
<div class="card"><div class="card-header"><h3>Recent Notifications</h3></div>
<div class="table-wrap"><table><thead><tr><th>User</th><th>Title</th><th>Message</th><th>Read</th><th>Sent</th></tr></thead><tbody>
<?php foreach($recent as $n):?><tr><td><?=htmlspecialchars($n['full_name'])?></td><td class="fw-700"><?=htmlspecialchars($n['title'])?></td><td class="text-2 text-sm"><?=htmlspecialchars(substr($n['body'],0,50))?></td><td><span class="badge <?=$n['is_read']?'badge-green':'badge-yellow'?>"><?=$n['is_read']?'Read':'Unread'?></span></td><td class="text-sm text-2"><?=date('M d, H:i',strtotime($n['created_at']))?></td></tr><?php endforeach;?>
<?php if(empty($recent)):?><tr><td colspan="5" class="text-3" style="text-align:center;padding:40px">No notifications</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
