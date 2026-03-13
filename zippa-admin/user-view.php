<?php
/** User Detail View */
require_once __DIR__ . '/includes/header.php';
$id = $_GET['id'] ?? ''; if(!$id){header('Location:users.php');exit;}
$u=db()->prepare("SELECT u.*, w.balance, w.pending_balance, w.virtual_account_number, w.virtual_bank_name, up.business_name, up.business_address FROM users u LEFT JOIN wallets w ON w.user_id=u.id LEFT JOIN user_profiles up ON up.user_id=u.id WHERE u.id=:id");
$u->execute(['id'=>$id]); $u=$u->fetch(); if(!$u){header('Location:users.php');exit;}
$orders=db()->prepare("SELECT COUNT(*) as cnt, COALESCE(SUM(total_fare),0) as total FROM orders WHERE customer_id=:id OR rider_id=:id OR vendor_id=:id");
$orders->execute(['id'=>$id]); $oStats=$orders->fetch();
$recentOrders=db()->prepare("SELECT order_number,total_fare,status,created_at FROM orders WHERE customer_id=:id OR rider_id=:id OR vendor_id=:id ORDER BY created_at DESC LIMIT 5");
$recentOrders->execute(['id'=>$id]); $ro=$recentOrders->fetchAll();
$txns=db()->prepare("SELECT wt.type,wt.amount,wt.description,wt.created_at FROM wallet_transactions wt JOIN wallets w ON wt.wallet_id=w.id WHERE w.user_id=:id ORDER BY wt.created_at DESC LIMIT 5");
$txns->execute(['id'=>$id]); $txns=$txns->fetchAll();
$docs=db()->prepare("SELECT * FROM kyc_documents WHERE user_id=:id ORDER BY created_at DESC");
$docs->execute(['id'=>$id]); $docs=$docs->fetchAll();
$backendUrl = "http://192.168.0.106:3001"; // Base URL for documents
function statusBdg($s){$m=['pending'=>'badge-yellow','accepted'=>'badge-blue','picked_up'=>'badge-cyan','in_transit'=>'badge-purple','delivered'=>'badge-green','completed'=>'badge-green','cancelled'=>'badge-red'];return '<span class="badge '.($m[$s]??'badge-yellow').'">'.$s.'</span>';}
?>
<div class="header-action-row mb-16">
    <a href="users.php" class="btn btn-ghost btn-sm"><i class="fa-solid fa-arrow-left"></i> Back to Users</a>
    <div class="action-row">
        <?php if($u['is_active']):?>
            <form method="POST" action="actions.php" style="display:inline" onsubmit="return confirm('Ban this user? They will not be able to login.')">
                <input type="hidden" name="user_id" value="<?=$u['id']?>">
                <input type="hidden" name="action" value="ban">
                <input type="hidden" name="redirect" value="user-view.php?id=<?=$u['id']?>">
                <button type="submit" class="btn btn-warning btn-sm"><i class="fa-solid fa-ban"></i> Ban Account</button>
            </form>
        <?php else:?>
            <form method="POST" action="actions.php" style="display:inline">
                <input type="hidden" name="user_id" value="<?=$u['id']?>">
                <input type="hidden" name="action" value="unban">
                <input type="hidden" name="redirect" value="user-view.php?id=<?=$u['id']?>">
                <button type="submit" class="btn btn-success btn-sm"><i class="fa-solid fa-check"></i> Restore Account</button>
            </form>
        <?php endif;?>
        
        <form method="POST" action="actions.php" style="display:inline" onsubmit="return confirm('CRITICAL: Delete this user account and all their data? This action cannot be undone.')">
            <input type="hidden" name="user_id" value="<?=$u['id']?>">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="redirect" value="users.php">
            <button type="submit" class="btn btn-danger btn-sm"><i class="fa-solid fa-trash"></i> Delete Account</button>
        </form>
    </div>
</div>

<!-- Premium User Hero Section -->
<div class="card mb-24" style="background: linear-gradient(135deg, var(--surface) 0%, #1e293b 100%); border: none; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.3);">
    <div class="card-body" style="padding: 32px; display: flex; align-items: center; gap: 24px;">
        <div class="avatar-lg" style="width: 80px; height: 80px; background: var(--brand); border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 800; color: #fff; box-shadow: 0 8px 16px rgba(59,130,246,0.3);">
            <?= strtoupper(substr($u['full_name'], 0, 1)) ?>
        </div>
        <div style="flex: 1;">
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 4px;">
                <h2 style="margin: 0; font-size: 1.5rem; font-weight: 800;"><?= htmlspecialchars($u['full_name']) ?></h2>
                <span class="badge badge-blue"><?= $u['role'] ?></span>
                <span class="badge <?= $u['is_active'] ? 'badge-green' : 'badge-red' ?>"><?= $u['is_active'] ? 'Active' : 'Banned' ?></span>
            </div>
            <p style="margin: 0; color: var(--text-2); font-size: 0.9rem;">
                <i class="fa-solid fa-envelope" style="width: 16px;"></i> <?= htmlspecialchars($u['email'] ?? '—') ?> 
                <span style="margin: 0 8px; opacity: 0.3;">|</span>
                <i class="fa-solid fa-phone" style="width: 16px;"></i> <?= htmlspecialchars($u['phone']) ?>
            </p>
            <div style="margin-top: 12px; display: flex; gap: 16px;">
                <div class="text-sm"><strong style="color: var(--brand);"><?= $oStats['cnt'] ?></strong> <span class="text-3">Orders</span></div>
                <div class="text-sm"><strong style="color: var(--green);">₦<?= number_format((float)$oStats['total'], 0) ?></strong> <span class="text-3">Volume</span></div>
                <div class="text-sm"><span class="text-3">Joined</span> <strong><?= date('M d, Y', strtotime($u['created_at'])) ?></strong></div>
            </div>
        </div>
        <div style="text-align: right;">
            <div style="font-size: 0.7rem; color: var(--text-3); text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-bottom: 4px;">Current Balance</div>
            <div style="font-size: 1.8rem; font-weight: 800; color: var(--green);">₦<?= number_format((float)($u['balance'] ?? 0), 2) ?></div>
            <div class="badge badge-yellow" style="margin-top: 8px;">KYC Status: <?= $u['kyc_status'] ?></div>
        </div>
    </div>
</div>

<div class="grid-2">
    <!-- Profile & Business Details -->
    <div class="card">
        <div class="card-header"><h3><i class="fa-solid fa-circle-info"></i> Account Details</h3></div>
        <div class="detail-grid">
            <div class="detail-item"><label>User ID</label><span><small style="opacity: 0.5; font-family: monospace;"><?= $u['id'] ?></small></span></div>
            <div class="detail-item"><label>Gender</label><span><?= htmlspecialchars($u['gender'] ?? 'Not specified') ?></span></div>
            <div class="detail-item full"><label>Address</label><span><?= htmlspecialchars($u['address'] ?? 'Not provided') ?></span></div>
            <div class="detail-item"><label>City</label><span><?= htmlspecialchars($u['city'] ?? '—') ?></span></div>
            <div class="detail-item"><label>State</label><span><?= htmlspecialchars($u['state'] ?? '—') ?></span></div>
            <div class="detail-item"><label>Last Seen</label><span><?= $u['last_login_at'] ? date('M d, H:i', strtotime($u['last_login_at'])) : 'Never' ?></span></div>
            <div class="detail-item"><label>Email Verified</label><span><i class="fa-solid fa-circle-check" style="color: var(--green);"></i> Yes</span></div>
            
            <?php if($u['business_name']): ?>
            <div class="detail-item full" style="background: rgba(59,130,246,0.05);"><label style="color: var(--brand);">Business Information</label></div>
            <div class="detail-item full"><label>Business Name</label><strong style="font-size: 1.1rem;"><?= htmlspecialchars($u['business_name']) ?></strong></div>
            <div class="detail-item full"><label>Business Address</label><span><?= htmlspecialchars($u['business_address'] ?? '—') ?></span></div>
            <?php endif; ?>
        </div>
    </div>

    <!-- Financial Summary -->
    <div>
        <div class="card">
            <div class="card-header"><h3><i class="fa-solid fa-wallet"></i> Wallet & Payout</h3></div>
            <div class="card-body">
                <div style="display: flex; gap: 12px; margin-bottom: 20px;">
                    <div style="flex: 1; padding: 16px; background: var(--surface-2); border-radius: 12px;">
                        <span class="text-3 text-sm">Available</span>
                        <h4 style="font-size: 1.2rem; margin-top: 4px;">₦<?= number_format((float)($u['balance'] ?? 0), 2) ?></h4>
                    </div>
                    <div style="flex: 1; padding: 16px; background: var(--surface-2); border-radius: 12px;">
                        <span class="text-3 text-sm">Escrow / Pending</span>
                        <h4 style="font-size: 1.2rem; margin-top: 4px; color: var(--yellow);">₦<?= number_format((float)($u['pending_balance'] ?? 0), 2) ?></h4>
                    </div>
                </div>
                <?php if($u['virtual_account_number']): ?>
                <div style="padding: 16px; border: 1px dashed var(--border-hl); border-radius: 12px;">
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 12px;">
                        <div style="width: 32px; height: 32px; background: rgba(59,130,246,0.1); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: var(--brand);">
                            <i class="fa-solid fa-building-columns"></i>
                        </div>
                        <strong class="text-sm">Paystack Virtual Account</strong>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <div style="font-size: 1.1rem; font-weight: 700; letter-spacing: 1px;"><?= htmlspecialchars($u['virtual_account_number']) ?></div>
                            <div class="text-3 text-sm"><?= htmlspecialchars($u['virtual_bank_name'] ?? 'Bank Transfer') ?></div>
                        </div>
                        <i class="fa-solid fa-shield-halved" style="font-size: 24px; opacity: 0.1;"></i>
                    </div>
                </div>
                <?php else: ?>
                <div class="empty-state" style="padding: 20px;">
                    <p class="text-sm">No virtual account assigned yet.</p>
                </div>
                <?php endif; ?>
            </div>
        </div>

        <!-- Role Specific Flags/Stats -->
        <?php if($u['role'] === 'rider'): ?>
        <div class="card">
            <div class="card-header"><h3><i class="fa-solid fa-motorcycle"></i> Logistics Status</h3></div>
            <div class="card-body">
                <div style="display: flex; align-items: center; justify-content: space-between;">
                    <div>
                        <div class="text-3 text-sm">Current Status</div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-top: 4px;">
                            <div style="width: 10px; height: 10px; border-radius: 50%; background: <?= $u['is_online'] ? 'var(--green)' : 'var(--text-3)' ?>;"></div>
                            <strong style="font-size: 0.9rem;"><?= $u['is_online'] ? 'Active & Online' : 'Offline' ?></strong>
                        </div>
                    </div>
                    <div class="badge badge-purple">Vehicle: Motorbike</div>
                </div>
            </div>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="grid-2">
    <!-- Transactions - Simplified but cleaner -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fa-solid fa-money-bill-transfer"></i> Recent Transactions</h3>
            <a href="#" class="text-sm" style="color: var(--brand);">View All</a>
        </div>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Type</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                <tbody>
                <?php foreach($txns as $t):?>
                <tr>
                    <td><div style="display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid <?= $t['type']==='credit'?'fa-circle-arrow-down':'fa-circle-arrow-up' ?>" style="color: <?= $t['type']==='credit'?'var(--green)':'var(--red)' ?>; font-size: 16px;"></i>
                        <span style="font-weight: 600;"><?= ucfirst($t['type']) ?></span>
                    </div></td>
                    <td><strong style="color: <?= $t['type']==='credit'?'var(--green)':'var(--text)' ?>;">₦<?= number_format((float)$t['amount'], 2) ?></strong></td>
                    <td><span class="badge badge-green">Completed</span></td>
                    <td class="text-3 text-sm"><?= date('M d, H:i', strtotime($t['created_at'])) ?></td>
                </tr>
                <?php endforeach;?>
                <?php if(empty($txns)):?><tr><td colspan="4" class="empty-state">No transactions recorded.</td></tr><?php endif;?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Active Orders -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fa-solid fa-box"></i> Order History</h3>
            <a href="#" class="text-sm" style="color: var(--brand);">View All</a>
        </div>
        <div class="table-wrap">
            <table>
                <thead><tr><th># Order</th><th>Fare</th><th>Status</th><th>Date</th></tr></thead>
                <tbody>
                <?php foreach($ro as $o):?>
                <tr>
                    <td style="color: var(--brand); font-weight: 700;">#<?=$o['order_number']?></td>
                    <td>₦<?=number_format((float)$o['total_fare'],0)?></td>
                    <td><?=statusBdg($o['status'])?></td>
                    <td class="text-3 text-sm"><?=date('M d',strtotime($o['created_at']))?></td>
                </tr>
                <?php endforeach;?>
                <?php if(empty($ro)):?><tr><td colspan="4" class="empty-state">No order history.</td></tr><?php endif;?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- KYC Verification Section - More Prominent -->
<div class="card mt-24" style="border: 1px solid <?= $u['kyc_status'] === 'pending' ? 'var(--yellow)' : 'var(--border)' ?>;">
    <div class="card-header" style="<?= $u['kyc_status'] === 'pending' ? 'background: rgba(245,158,11,0.05);' : '' ?>">
        <div>
            <h3 style="margin-bottom: 4px;"><i class="fa-solid fa-shield-check"></i> Identity & Compliance (KYC)</h3>
            <span class="text-3 text-sm">Status: </span><span class="badge <?=$u['kyc_status']==='verified'?'badge-green':($u['kyc_status']==='rejected'?'badge-red':'badge-yellow')?>"><?=$u['kyc_status']?></span>
        </div>
        <?php if($u['kyc_status'] === 'pending'): ?>
        <div class="action-row">
            <form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$u['id']?>"><input type="hidden" name="action" value="kyc_approve"><input type="hidden" name="redirect" value="user-view.php?id=<?=$u['id']?>"><button class="btn btn-success"><i class="fa-solid fa-check"></i> Approve All</button></form>
            <form method="POST" action="actions.php" style="display:inline"><input type="hidden" name="user_id" value="<?=$u['id']?>"><input type="hidden" name="action" value="kyc_reject"><input type="hidden" name="redirect" value="user-view.php?id=<?=$u['id']?>"><button class="btn btn-danger"><i class="fa-solid fa-times"></i> Reject All</button></form>
        </div>
        <?php endif; ?>
    </div>
    <div class="card-body">
        <?php if(empty($docs)): ?>
            <div class="empty-state">
                <i class="fa-solid fa-file-circle-exclamation" style="font-size: 40px; color: var(--text-3); margin-bottom: 12px;"></i>
                <p>No documents uploaded yet. Identity has not been submitted for review.</p>
            </div>
        <?php else: ?>
            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px;">
                <?php foreach($docs as $doc): ?>
                <div style="border: 1px solid var(--border); border-radius: 16px; overflow: hidden; background: var(--surface-2); transition: transform 0.2s; cursor: pointer;" onclick="window.open('<?=$fullUrl?>', '_blank')">
                    <div style="padding: 16px; display: flex; justify-content: space-between; align-items: center; background: rgba(255,255,255,0.02);">
                        <div>
                            <div class="text-3" style="font-size: 0.65rem; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px;">Document Type</div>
                            <strong style="font-size: 0.95rem;"><?= strtoupper(str_replace('_', ' ', $doc['document_type'])) ?></strong>
                        </div>
                        <span class="badge <?=$doc['status']==='approved'?'badge-green':($doc['status']==='rejected'?'badge-red':'badge-yellow')?>"><?=$doc['status']?></span>
                    </div>
                    <?php 
                        $isPdf = str_ends_with(strtolower($doc['document_url']), '.pdf');
                        $fullUrl = $backendUrl . $doc['document_url'];
                    ?>
                    <div style="aspect-ratio: 16/10; background: #000; position: relative;">
                        <?php if($isPdf): ?>
                            <div style="height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center;">
                                <i class="fa-solid fa-file-pdf" style="font-size: 56px; color: var(--red); margin-bottom: 12px;"></i>
                                <span class="text-sm">Download PDF Document</span>
                            </div>
                        <?php else: ?>
                            <img src="<?=$fullUrl?>" alt="KYC" style="width: 100%; height: 100%; object-fit: cover; opacity: 0.8;">
                            <div style="position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.8), transparent 40%); display: flex; align-items: flex-end; padding: 16px;">
                                <div class="text-sm" style="color: #fff; text-shadow: 0 2px 4px rgba(0,0,0,0.5);"><i class="fa-solid fa-magnifying-glass-plus"></i> Click to enlarge</div>
                            </div>
                        <?php endif; ?>
                    </div>
                    <div style="padding: 16px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                            <span class="text-3 text-sm">ID Number</span>
                            <span class="text-sm fw-700"><?= htmlspecialchars($doc['document_number'] ?: 'N/A') ?></span>
                        </div>
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <span class="text-3 text-sm">Submitted</span>
                            <span class="text-3" style="font-size: 0.75rem;"><?= date('M d, Y', strtotime($doc['created_at'])) ?></span>
                        </div>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
