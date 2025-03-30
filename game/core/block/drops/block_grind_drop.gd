class_name BlockGrindDrop
extends Resource

@export var item: Item



func get_drop_inv_item()-> InventoryItem:
	return InventoryItem.new(item)
