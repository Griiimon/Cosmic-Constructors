extends ObjectEntity

const STACK_SIZE= 10

var stored_item: Item
var count: int



func can_item_catcher_catch_item(inv_item: InventoryItem)-> bool:
	return stored_item == null or ( inv_item.item == stored_item and find_tile_with_space() )


func _on_item_catcher_caught_item(inv_item: InventoryItem) -> void:
	stored_item= inv_item.item
	var tile: Marker3D= find_tile_with_space()
	assert(tile)
	add_to_stack(tile)
	count+= 1


func find_tile_with_space()-> Marker3D:
	var grid: Node3D
	
	match stored_item.storage_size:
		Item.StorageSize.TINY:
			grid= %"Tiny Item Grid"
		Item.StorageSize.SMALL:
			grid= %"Small Item Grid"
		Item.StorageSize.LARGE:
			grid= %"Large Grid"
	
	for node: Marker3D in grid.find_children("*", "Marker3D") + ( [grid] if grid is Marker3D else [] ):
		if node.get_child_count() < STACK_SIZE:
			return node
	return null


func add_to_stack(tile: Marker3D):
	var item_instance: Node3D= stored_item.model.instantiate()
	tile.add_child(item_instance)
	item_instance.position.y+= tile.get_child_count() * 0.1


func can_pull_pullable()-> bool:
	return true
