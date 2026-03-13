<?php
/** Users Management with View/Ban/Delete */
require_once __DIR__ . '/includes/header.php';
$msg = $_GET['msg'] ?? '';
$search = trim($_GET['search'] ?? '');
$role = $_GET['role'] ?? '';
$kyc = $_GET['kyc'] ?? '';

$sql = "SELECT u.id, u.full_name, u.email, u.phone, u.role, u.kyc_status, u.is_active, u.is_online, u.created_at, w.balance FROM users u LEFT JOIN wallets w ON w.user_id = u.id WHERE 1=1";
$params = [];
if ($role) { $sql .= " AND u.role = :role"; $params['role'] = $role; }
if ($kyc) { $sql .= " AND u.kyc_status = :kyc"; $params['kyc'] = $kyc; }
if ($search) { $sql .= " AND (u.full_name ILIKE :s OR u.email ILIKE :s OR u.phone ILIKE :s)"; $params['s'] = "%{$search}%"; }
$sql .= " ORDER BY u.created_at DESC";
$stmt = db()->prepare($sql); $stmt->execute($params); $users = $stmt->fetchAll();
function rBadge($r){$m=['customer'=>'badge-blue','rider'=>'badge-purple','vendor'=>'badge-green','admin'=>'badge-red'];return '<span class="badge '.($m[$r]??'badge-blue').'">'.htmlspecialchars($r).'</span>';}
function kBadge($s){$m=['verified'=>'badge-green','pending'=>'badge-yellow','rejected'=>'badge-red','unverified'=>'badge-cyan'];return '<span class="badge '.($m[$s]??'badge-cyan').'">'.htmlspecialchars($s).'</span>';}
function aColor($r){return ['customer'=>'blue','rider'=>'purple','vendor'=>'green','admin'=>'yellow'][$r]??'blue';}
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="card">
    <form method="GET" class="filter-bar">
        <input type="text" name="search" class="form-control" placeholder="Search by name, email or phone..." value="<?=htmlspecialchars($search)?>" style="min-width:220px">
        <select name="role" class="form-control" style="min-width:120px"><option value="">All Roles</option>
            <option value="customer" <?=$role==='customer'?'selected':''?>>Customers</option>
            <option value="rider" <?=$role==='rider'?'selected':''?>>Riders</option>
            <option value="vendor" <?=$role==='vendor'?'selected':''?>>Vendors</option>
            <option value="admin" <?=$role==='admin'?'selected':''?>>Admins</option></select>
        <select name="kyc" class="form-control" style="min-width:120px"><option value="">All KYC</option>
            <option value="verified" <?=$kyc==='verified'?'selected':''?>>Verified</option>
            <option value="pending" <?=$kyc==='pending'?'selected':''?>>Pending</option>
            <option value="rejected" <?=$kyc==='rejected'?'selected':''?>>Rejected</option>
            <option value="unverified" <?=$kyc==='unverified'?'selected':''?>>Unverified</option></select>
        <button type="submit" class="btn btn-primary btn-sm"><i class="fa-solid fa-search"></i> Filter</button>
        <?php if($search||$role||$kyc):?><a href="users.php" class="btn btn-ghost btn-sm">Clear</a><?php endif;?>
        <span class="text-2 text-sm" style="margin-left:auto"><?=count($users)?> users</span>
        <a href="actions.php?action=export&role=<?=$role?>" class="btn btn-ghost btn-sm"><i class="fa-solid fa-download"></i> CSV</a>
    </form>
    <div class="table-wrap"><table><thead><tr><th>User</th><th>Role</th><th>KYC</th><th>Balance</th><th>Status</th><th>Joined</th><th>Actions</th></tr></thead><tbody>
    <?php foreach($users as $u):?>
    <tr>
        <td><div class="user-cell"><div class="avatar-sm <?=aColor($u['role'])?>"><?=strtoupper(substr($u['full_name'],0,1))?></div><div class="user-meta"><strong><?=htmlspecialchars($u['full_name'])?></strong><small><?=htmlspecialchars($u['email']?:$u['phone'])?></small></div></div></td>
        <td><?=rBadge($u['role'])?></td>
        <td><?=kBadge($u['kyc_status'])?></td>
        <td class="fw-700">₦<?=number_format((float)($u['balance']??0),2)?></td>
        <td><?php if($u['is_active']):?><span class="badge badge-green"><?=$u['is_online']?'Online':'Active'?></span><?php else:?><span class="badge badge-red">Banned</span><?php endif;?></td>
        <td class="text-2 text-sm"><?=date('M d, Y',strtotime($u['created_at']))?></td>
        <td>
            <div class="action-row">
                <a href="user-view.php?id=<?=$u['id']?>" class="btn-icon" title="View"><i class="fa-solid fa-eye"></i></a>
                <?php if($u['role']!=='admin'):?>
                <?php if($u['is_active']):?>
                <form method="POST" action="actions.php" style="display:inline" onsubmit="return confirm('Ban this user?')"><input type="hidden" name="user_id" value="<?=$u['id']?>"><input type="hidden" name="action" value="ban"><input type="hidden" name="redirect" value="users.php"><button type="submit" class="btn-icon" title="Ban"><i class="fa-solid fa-ban"></i></button></form>
                <?php else:?>
                <form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$u['id']?>"><input type="hidden" name="action" value="unban"><input type="hidden" name="redirect" value="users.php"><button type="submit" class="btn-icon" title="Unban"><i class="fa-solid fa-check"></i></button></form>
                <?php endif;?>
                <form method="POST" action="actions.php" style="display:inline" onsubmit="return confirm('Delete this user permanently?')"><input type="hidden" name="user_id" value="<?=$u['id']?>"><input type="hidden" name="action" value="delete"><input type="hidden" name="redirect" value="users.php"><button type="submit" class="btn-icon danger" title="Delete"><i class="fa-solid fa-trash"></i></button></form>
                <?php endif;?>
            </div>
        </td>
    </tr>
    <?php endforeach;?>
    <?php if(empty($users)):?><tr><td colspan="7" class="empty-state"><i class="fa-solid fa-users"></i><p>No users found</p></td></tr><?php endif;?>
    </tbody></table></div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
