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
        /** @var PDO $db */
        $db = db();
        try {
            $db->beginTransaction();
            
            // 1. Get Wallet ID
            $w = $db->prepare("SELECT id FROM wallets WHERE user_id = :id");
            $w->execute(['id'=>$userId]);
            $wallet = $w->fetch();
            
            // 2. Get User Orders
            $o = $db->prepare("SELECT id FROM orders WHERE customer_id = :id OR rider_id = :id OR vendor_id = :id");
            $o->execute(['id'=>$userId]);
            $orderIds = $o->fetchAll(PDO::FETCH_COLUMN);
            
            if (!empty($orderIds)) {
                $placeholders = implode(',', array_fill(0, count($orderIds), '?'));
                // 3. Delete Order Chat Messages
                $db->prepare("DELETE FROM order_chat_messages WHERE order_id IN ($placeholders)")->execute($orderIds);
                // 4. Delete Ratings linked to these orders
                $db->prepare("DELETE FROM ratings WHERE order_id IN ($placeholders)")->execute($orderIds);
            }
            
            // 5. Delete other ratings (where user is rater or ratee)
            $db->prepare("DELETE FROM ratings WHERE from_user = :id OR to_user = :id")->execute(['id'=>$userId]);
            
            // 6. Wallet Transactions
            if ($wallet) {
                $db->prepare("DELETE FROM wallet_transactions WHERE wallet_id = :wid")->execute(['wid'=>$wallet['id']]);
                $db->prepare("DELETE FROM wallets WHERE id = :wid")->execute(['wid'=>$wallet['id']]);
            }
            
            // 7. KYC, Profiles, etc.
            $db->prepare("DELETE FROM kyc_documents WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM user_profiles WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM refresh_tokens WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM notifications WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM user_favorites WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM user_landmarks WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM withdrawals WHERE user_id = :id")->execute(['id'=>$userId]);
            $db->prepare("DELETE FROM whatsapp_sessions WHERE user_id = :id")->execute(['id'=>$userId]);
            
            // 8. Delete Orders
            $db->prepare("DELETE FROM orders WHERE customer_id = :id OR rider_id = :id OR vendor_id = :id")->execute(['id'=>$userId]);
            
            // 9. Finally, Delete User
            $db->prepare("DELETE FROM users WHERE id = :id")->execute(['id'=>$userId]);
            
            $db->commit();
            header("Location: users.php?msg=User+deleted+completely");
        } catch (Exception $e) {
            $db->rollBack();
            header("Location: user-view.php?id=$userId&error=Delete+failed:+" . urlencode($e->getMessage()));
        }
        break;
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
