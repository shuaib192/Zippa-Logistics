<?php
/** Category Management CRUD */
require_once __DIR__ . '/includes/header.php';
$msg=$_GET['msg']??'';
if($_SERVER['REQUEST_METHOD']==='POST'){
    $act=$_POST['act']??'';
    if($act==='create'){
        db()->prepare("INSERT INTO vendor_categories(name,icon_name) VALUES(:n,:i)")->execute(['n'=>trim($_POST['name']),'i'=>$_POST['icon_name']??'']);
        header('Location:categories.php?msg=Category+created');exit;
    }
    if($act==='delete'){
        db()->prepare("DELETE FROM vendor_categories WHERE id=:id")->execute(['id'=>$_POST['cat_id']]);
        header('Location:categories.php?msg=Category+deleted');exit;
    }
    if($act==='toggle'){
        db()->prepare("UPDATE vendor_categories SET is_active = NOT is_active WHERE id=:id")->execute(['id'=>$_POST['cat_id']]);
        header('Location:categories.php?msg=Category+updated');exit;
    }
}
$cats=db()->query("SELECT vc.*, (SELECT COUNT(*) FROM products p WHERE p.category_id=vc.id) as product_count FROM vendor_categories vc ORDER BY vc.name")->fetchAll();
?>
<?php if($msg):?><div class="alert alert-success"><?=htmlspecialchars($msg)?></div><?php endif;?>
<div class="grid-2 mb-24">
<div class="card"><div class="card-header"><h3><i class="fa-solid fa-plus"></i> Add Category</h3></div><div class="card-body">
<form method="POST"><input type="hidden" name="act" value="create">
<div class="form-group"><label>Category Name</label><input name="name" class="form-control" required placeholder="e.g. Electronics"></div>
<div class="form-group"><label>Icon Name (optional)</label><input name="icon_name" class="form-control" placeholder="e.g. smartphone"></div>
<button type="submit" class="btn btn-primary"><i class="fa-solid fa-plus"></i> Create Category</button>
</form></div></div>
<div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-tags"></i></div><div class="stat-value"><?=count($cats)?></div><div class="stat-label">Total Categories</div></div>
</div>
<div class="card"><div class="card-header"><h3>All Categories</h3></div>
<div class="table-wrap"><table><thead><tr><th>Name</th><th>Products</th><th>Status</th><th>Actions</th></tr></thead><tbody>
<?php foreach($cats as $c):?><tr>
<td class="fw-700"><?=htmlspecialchars($c['name'])?></td>
<td><span class="badge badge-blue"><?=$c['product_count']?> products</span></td>
<td><span class="badge <?=$c['is_active']?'badge-green':'badge-red'?>"><?=$c['is_active']?'Active':'Disabled'?></span></td>
<td><div class="action-row">
<form method="POST" style="display:inline"><input type="hidden" name="act" value="toggle"><input type="hidden" name="cat_id" value="<?=$c['id']?>"><button class="btn-icon"><i class="fa-solid fa-power-off"></i></button></form>
<form method="POST" style="display:inline" onsubmit="return confirm('Delete category? Products will be uncategorized.')"><input type="hidden" name="act" value="delete"><input type="hidden" name="cat_id" value="<?=$c['id']?>"><button class="btn-icon danger"><i class="fa-solid fa-trash"></i></button></form>
</div></td></tr><?php endforeach;?>
<?php if(empty($cats)):?><tr><td colspan="4" class="text-3" style="text-align:center;padding:40px">No categories</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
