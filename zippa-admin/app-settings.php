<?php
/** App Settings - Manage Fare Prices */
require_once __DIR__ . '/includes/header.php';

$success = '';
$error = '';

// Handle Update
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_settings'])) {
    try {
        $base_fare = $_POST['base_fare'] ?? '500';
        $per_km_fare = $_POST['per_km_fare'] ?? '150';

        $db = db();
        
        // Update Base Fare
        $stmt = $db->prepare("UPDATE settings SET value = :val, updated_at = NOW() WHERE key = 'base_fare'");
        $stmt->execute(['val' => $base_fare]);

        // Update Per KM Fare
        $stmt = $db->prepare("UPDATE settings SET value = :val, updated_at = NOW() WHERE key = 'per_km_fare'");
        $stmt->execute(['val' => $per_km_fare]);

        $success = 'Fare settings updated successfully! Your live app will now use these prices.';
    } catch (Exception $e) {
        $error = 'Error updating settings: ' . $e->getMessage();
    }
}

// Fetch current values
$settings = [];
try {
    $rows = db()->query("SELECT key, value FROM settings WHERE key IN ('base_fare', 'per_km_fare')")->fetchAll();
    foreach ($rows as $row) {
        $settings[$row['key']] = $row['value'];
    }
} catch (Exception $e) {
    $error = 'Could not load settings: ' . $e->getMessage();
}

$base = $settings['base_fare'] ?? '500';
$km = $settings['per_km_fare'] ?? '150';
?>

<div class="row">
    <div class="col-md-6">
        <div class="card shadow-sm border-0 mb-4">
            <div class="card-header bg-white py-3">
                <h5 class="mb-0 fw-bold text-primary"><i class="fa-solid fa-money-bill-transfer me-2"></i> Delivery Fare Configuration</h5>
            </div>
            <div class="card-body p-4">
                <?php if ($success): ?>
                    <div class="alert alert-success border-0 shadow-sm mb-4"><i class="fa-solid fa-check-circle me-2"></i> <?= $success ?></div>
                <?php endif; ?>
                <?php if ($error): ?>
                    <div class="alert alert-danger border-0 shadow-sm mb-4"><i class="fa-solid fa-exclamation-triangle me-2"></i> <?= $error ?></div>
                <?php endif; ?>

                <form method="POST">
                    <div class="mb-4">
                        <label class="form-label fw-600 text-secondary">Base Fare (₦)</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light border-0">₦</span>
                            <input type="number" name="base_fare" class="form-control bg-light border-0" value="<?= htmlspecialchars($base) ?>" required>
                        </div>
                        <small class="text-muted mt-1 d-block">The initial starting price for any delivery.</small>
                    </div>

                    <div class="mb-4">
                        <label class="form-label fw-600 text-secondary">Price per Kilometer (₦)</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light border-0">₦</span>
                            <input type="number" name="per_km_fare" class="form-control bg-light border-0" value="<?= htmlspecialchars($km) ?>" required>
                        </div>
                        <small class="text-muted mt-1 d-block">Additional cost added for every KM traveled.</small>
                    </div>

                    <button type="submit" name="update_settings" class="btn btn-primary w-100 py-3 fw-bold shadow-sm">
                        <i class="fa-solid fa-save me-2"></i> Apply Changes
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-6">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-header bg-white py-3">
                <h5 class="mb-0 fw-bold text-secondary"><i class="fa-solid fa-info-circle me-2"></i> How it works</h5>
            </div>
            <div class="card-body p-4">
                <p class="text-secondary">Changes made here are <strong>instantly</strong> applied to your live backend on Render.</p>
                <div class="bg-light p-3 rounded-3 mb-3">
                    <p class="mb-2 fw-bold text-primary">Calculation Formula:</p>
                    <code class="d-block text-dark">Total = Base Fare + (Distance × Per KM Fare)</code>
                </div>
                <p class="text-muted small">Note: Your backend fetches these values directly from Supabase. Make sure your local admin panel is connected to the cloud database to see effects.</p>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
