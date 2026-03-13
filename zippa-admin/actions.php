<?php
/** User Actions Handler */
require_once __DIR__ . '/config/auth.php';
requireLogin();
$admin = getAdmin();
$action = $_POST['action'] ?? $_GET['action'] ?? '';
$userId = $_POST['user_id'] ?? $_GET['user_id'] ?? '';
$redirect = $_POST['redirect'] ?? 'users.php';

if (!$userId && $action !== 'export') { header("Location: $redirect"); exit; }

switch ($action) {
    case 'ban':
        db()->prepare("UPDATE users SET is_active = false, updated_at = NOW() WHERE id = :id")->execute(['id'=>$userId]);
        header("Location: $redirect?msg=User+banned+successfully"); break;
    case 'unban':
        db()->prepare("UPDATE users SET is_active = true, updated_at = NOW() WHERE id = :id")->execute(['id'=>$userId]);
        header("Location: $redirect?msg=User+unbanned+successfully"); break;
    case 'delete':
        // Soft approach: deactivate + clear data
        db()->prepare("UPDATE users SET is_active = false, email = CONCAT('deleted_', id, '@removed.com'), phone = CONCAT('del_', LEFT(id::text,8)), updated_at = NOW() WHERE id = :id")->execute(['id'=>$userId]);
        header("Location: $redirect?msg=User+deleted+successfully"); break;
    case 'kyc_approve':
        db()->prepare("UPDATE users SET kyc_status = 'verified', updated_at = NOW() WHERE id = :id")->execute(['id'=>$userId]);
        db()->prepare("UPDATE kyc_documents SET status = 'approved', reviewed_by = :admin, reviewed_at = NOW() WHERE user_id = :uid AND status = 'pending'")->execute(['admin'=>$admin['id'],'uid'=>$userId]);
        header("Location: $redirect?msg=KYC+approved"); break;
    case 'kyc_reject':
        db()->prepare("UPDATE users SET kyc_status = 'rejected', updated_at = NOW() WHERE id = :id")->execute(['id'=>$userId]);
        db()->prepare("UPDATE kyc_documents SET status = 'rejected', reviewed_by = :admin, reviewed_at = NOW() WHERE user_id = :uid AND status = 'pending'")->execute(['admin'=>$admin['id'],'uid'=>$userId]);
        header("Location: $redirect?msg=KYC+rejected"); break;
    case 'export':
        $role = $_GET['role'] ?? '';
        $sql = "SELECT full_name, email, phone, role, kyc_status, is_active, created_at FROM users";
        if ($role) { $stmt = db()->prepare("$sql WHERE role = :r ORDER BY created_at DESC"); $stmt->execute(['r'=>$role]); }
        else { $stmt = db()->query("$sql ORDER BY created_at DESC"); }
        $users = $stmt->fetchAll();
        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="users_export_'.date('Y-m-d').'.csv"');
        $fp = fopen('php://output', 'w');
        fputcsv($fp, ['Name','Email','Phone','Role','KYC Status','Active','Joined']);
        foreach ($users as $u) { fputcsv($fp, [$u['full_name'],$u['email'],$u['phone'],$u['role'],$u['kyc_status'],$u['is_active']?'Yes':'No',date('Y-m-d',strtotime($u['created_at']))]); }
        fclose($fp); exit;
    default:
        header("Location: $redirect"); break;
}
exit;
