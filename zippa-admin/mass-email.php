<?php
/** Mass Email */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
if($_SERVER['REQUEST_METHOD']==='POST'){
    $target=$_POST['target']??'all';
    $subject=trim($_POST['subject']??'');
    $body=trim($_POST['body']??'');
    if($subject&&$body){
        $sql="SELECT email,full_name FROM users WHERE email IS NOT NULL AND email != ''";
        if($target!=='all') $sql.=" AND role='".addslashes($target)."'";
        $recipients=db()->query($sql)->fetchAll();
        $sent=0;$failed=0;
        foreach($recipients as $r){
            $headers="From: Zippa Logistics <noreply@zippalogistics.com>\r\nContent-Type: text/html; charset=UTF-8\r\n";
            $html="<div style='font-family:Arial;max-width:600px;margin:0 auto;padding:20px'>";
            $html.="<h2 style='color:#3B82F6'>$subject</h2>";
            $html.="<p>Hi ".htmlspecialchars($r['full_name']).",</p>";
            $html.="<div style='padding:16px;background:#f8f9fa;border-radius:8px;margin:16px 0'>".nl2br(htmlspecialchars($body))."</div>";
            $html.="<p style='color:#999;font-size:12px'>— Zippa Logistics Team</p></div>";
            if(@mail($r['email'],$subject,$html,$headers)) $sent++; else $failed++;
        }
        // Also store as notifications
        $stmt=db()->prepare("INSERT INTO notifications(user_id,title,body,type) VALUES(:uid,:t,:b,'email')");
        foreach($recipients as $r){
            $uid=db()->prepare("SELECT id FROM users WHERE email=:e");$uid->execute(['e'=>$r['email']]);$uid=$uid->fetchColumn();
            if($uid) $stmt->execute(['uid'=>$uid,'t'=>$subject,'b'=>$body]);
        }
        header("Location:mass-email.php?msg=Email+sent+to+".count($recipients)."+recipients+(mail:$sent,+failed:$failed)");exit;
    }
}
$totalEmails=db()->query("SELECT COUNT(*) FROM users WHERE email IS NOT NULL AND email != ''")->fetchColumn();
$byRole=db()->query("SELECT role,COUNT(*) as cnt FROM users WHERE email IS NOT NULL AND email != '' GROUP BY role")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="grid-2">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-paper-plane"></i> Compose Mass Email</h3></div><div class="card-body">
<form method="POST">
<div class="form-group"><label>Target Audience</label><select name="target" class="form-control">
<option value="all">All Users (<?=$totalEmails?> emails)</option>
<?php foreach($byRole as $r):?><option value="<?=$r['role']?>"><?=ucfirst($r['role'])?>s (<?=$r['cnt']?>)</option><?php endforeach;?>
</select></div>
<div class="form-group"><label>Subject</label><input name="subject" class="form-control" required placeholder="e.g. Important Service Update"></div>
<div class="form-group"><label>Message Body</label><textarea name="body" class="form-control" rows="8" required placeholder="Write your email content here..."></textarea></div>
<button type="submit" class="btn btn-primary" onclick="return confirm('Send email to all selected users?')"><i class="fa-solid fa-paper-plane"></i> Send Mass Email</button>
</form></div></div>
<div>
<div class="stat-card mb-16"><div class="stat-icon blue"><i class="fa-solid fa-envelope"></i></div><div class="stat-value"><?=$totalEmails?></div><div class="stat-label">Total Email Addresses</div></div>
<?php foreach($byRole as $r):?>
<div class="stat-card mb-16"><div class="stat-icon <?=['customer'=>'green','rider'=>'purple','vendor'=>'yellow','admin'=>'red'][$r['role']]??'blue'?>"><i class="fa-solid fa-<?=['customer'=>'user','rider'=>'motorcycle','vendor'=>'store','admin'=>'shield-halved'][$r['role']]??'user'?>"></i></div><div class="stat-value"><?=$r['cnt']?></div><div class="stat-label"><?=ucfirst($r['role'])?>s</div></div>
<?php endforeach;?>
</div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
