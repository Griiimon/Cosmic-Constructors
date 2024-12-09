class_name InventoryItem
extends Resource

@export var item: Item
@export var count: int



func _init(_item: Item, _count: int= 1):
	item= _item
	count= _count
