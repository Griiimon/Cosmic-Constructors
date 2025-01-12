extends BlockInstance

@onready var item_ejector: ItemEjector = $"Item Ejector"

var linked_container: ItemContainer



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	#var linked_block: GridBlock= grid.get_block_local(Vector3i((Vector3(grid_block.local_pos) + grid_block.get_local_basis().z).floor()))
	var linked_block: BaseGridBlock= grid.get_block_local_direction(grid_block.local_pos, grid_block.get_local_basis().z)
	if linked_block:
		var container: ItemContainer= BaseBlockComponent.get_from_block(linked_block, ItemContainer.NODE_NAME)
		if container:
			linked_container= container


func physics_tick(grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if not linked_container: return
	if linked_container.is_empty(): return
	
	var orig_inv_item: InventoryItem= linked_container.inventory.slots[0]
	if item_ejector.can_eject(orig_inv_item):
		var eject_item: InventoryItem= orig_inv_item.duplicate()
		eject_item.count= min(orig_inv_item.count, orig_inv_item.item.get_max_unit_size())
		item_ejector.eject_item(eject_item, grid.world)
		linked_container.inventory.sub_from_item(orig_inv_item, eject_item.count)
