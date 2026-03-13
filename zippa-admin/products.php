<?php
/** Products Management */
require_once __DIR__ . '/includes/header.php';
$search=trim($_GET['search']??'');$cat=$_GET['cat']??'';
$sql="SELECT p.*,u.full_name as vendor,vc.name as category FROM products p LEFT JOIN users u ON p.vendor_id=u.id LEFT JOIN vendor_categories vc ON p.category_id=vc.id WHERE 1=1";
$pm=[];
if($search){$sql.=" AND (p.name ILIKE :s OR u.full_name ILIKE :s)";$pm['s']="%$search%";}
if($cat){$sql.=" AND p.category_id=:c";$pm['c']=$cat;}
$sql.=" ORDER BY p.created_at DESC";$stmt=db()->prepare($sql);$stmt->execute($pm);$products=$stmt->fetchAll();
$cats=db()->query("SELECT id,name FROM vendor_categories ORDER BY name")->fetchAll();
?>
<div class="card"><form method="GET" class="filter-bar">
<input type="text" name="search" class="form-control" placeholder="Search products..." value="<?=htmlspecialchars($search)?>">
<select name="cat" class="form-control" style="min-width:140px"><option value="">All Categories</option>
<?php foreach($cats as $c):?><option value="<?=$c['id']?>" <?=$cat===$c['id']?'selected':''?>><?=htmlspecialchars($c['name'])?></option><?php endforeach;?></select>
<button type="submit" class="btn btn-primary btn-sm"><i class="fa-solid fa-search"></i></button>
<?php if($search||$cat):?><a href="products.php" class="btn btn-ghost btn-sm">Clear</a><?php endif;?>
<span class="text-2 text-sm" style="margin-left:auto"><?=count($products)?> products</span></form>
<div class="table-wrap"><table><thead><tr><th>Product</th><th>Vendor</th><th>Category</th><th>Price</th><th>Stock</th><th>Status</th></tr></thead><tbody>
<?php foreach($products as $p):?><tr>
<td class="fw-700"><?=htmlspecialchars($p['name'])?></td>
<td><?=htmlspecialchars($p['vendor']??'N/A')?></td>
<td><span class="badge badge-blue"><?=htmlspecialchars($p['category']??'—')?></span></td>
<td class="fw-700">₦<?=number_format((float)$p['price'],2)?></td>
<td><?=(int)$p['stock_quantity']?></td>
<td><span class="badge <?=$p['is_available']?'badge-green':'badge-red'?>"><?=$p['is_available']?'Available':'Unavailable'?></span></td>
</tr><?php endforeach;?>
<?php if(empty($products)):?><tr><td colspan="6" class="text-3" style="text-align:center;padding:40px">No products</td></tr><?php endif;?>
</tbody></table></div></div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
