<?php
/** Settings */
require_once __DIR__ . '/includes/header.php';
$success='';$error='';
if($_SERVER['REQUEST_METHOD']==='POST'&&isset($_POST['change_password'])){
    $cur=$_POST['current_password']??'';$new=$_POST['new_password']??'';$conf=$_POST['confirm_password']??'';
    if($new!==$conf) $error='Passwords do not match.';
    elseif(strlen($new)<6) $error='Min 6 characters.';
    else{$admin=getAdmin();$stmt=db()->prepare("SELECT password_hash FROM users WHERE id=:id");$stmt->execute(['id'=>$admin['id']]);$row=$stmt->fetch();
    if($row&&password_verify($cur,$row['password_hash'])){db()->prepare("UPDATE users SET password_hash=:h,updated_at=NOW() WHERE id=:id")->execute(['h'=>password_hash($new,PASSWORD_BCRYPT),'id'=>$admin['id']]);$success='Password updated!';}
    else $error='Current password is incorrect.';}
}
$dbV=db()->query("SELECT version()")->fetchColumn();
$tables=db()->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")->fetchColumn();
$dbSize=db()->query("SELECT pg_size_pretty(pg_database_size('zippa_logistics'))")->fetchColumn();
?>
<?php if($success):?><div class="alert alert-success"><?=$success?></div><?php endif;?>
<?php if($error):?><div class="alert alert-danger"><?=$error?></div><?php endif;?>
<div class="grid-2">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-lock"></i> Change Password</h3></div><div class="card-body">
<form method="POST"><div class="form-group"><label>Current Password</label><input type="password" name="current_password" class="form-control" required></div>
<div class="form-group"><label>New Password</label><input type="password" name="new_password" class="form-control" required minlength="6"></div>
<div class="form-group"><label>Confirm</label><input type="password" name="confirm_password" class="form-control" required></div>
<button type="submit" name="change_password" value="1" class="btn btn-primary"><i class="fa-solid fa-save"></i> Update</button></form></div></div>
<div><div class="card mb-16"><div class="card-header"><h3><i class="fa-solid fa-server"></i> System</h3></div><div class="card-body">
<table style="width:100%">
<tr><td class="text-2 text-sm" style="padding:8px 0">PHP</td><td class="fw-700" style="padding:8px 0"><?=phpversion()?></td></tr>
<tr><td class="text-2 text-sm" style="padding:8px 0;border-top:1px solid var(--border)">PostgreSQL</td><td class="fw-700" style="padding:8px 0;border-top:1px solid var(--border)"><?=htmlspecialchars(substr($dbV,0,35))?></td></tr>
<tr><td class="text-2 text-sm" style="padding:8px 0;border-top:1px solid var(--border)">DB Size</td><td class="fw-700" style="padding:8px 0;border-top:1px solid var(--border)"><?=$dbSize?></td></tr>
<tr><td class="text-2 text-sm" style="padding:8px 0;border-top:1px solid var(--border)">Tables</td><td class="fw-700" style="padding:8px 0;border-top:1px solid var(--border)"><?=$tables?></td></tr>
<tr><td class="text-2 text-sm" style="padding:8px 0;border-top:1px solid var(--border)">OS</td><td class="fw-700" style="padding:8px 0;border-top:1px solid var(--border)"><?=PHP_OS?></td></tr>
</table></div></div>
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-user-shield"></i> Admin</h3></div><div class="card-body">
<div class="user-cell"><div class="avatar-sm blue"><?=strtoupper(substr(getAdmin()['name'],0,1))?></div><div class="user-meta"><strong><?=htmlspecialchars(getAdmin()['name'])?></strong><small><?=htmlspecialchars(getAdmin()['email'])?></small></div></div>
</div></div></div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
