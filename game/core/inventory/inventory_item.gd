class_name InventoryItem
extends Resource

@export var item: Item
@export var count: int



func _init(_item: Item, _count: int= 1):
	item= _item
	count= _count


func serialize()-> Dictionary:
	return { "item": item.get_display_name(), "count": count }


static func deserialize(data: Dictionary)-> InventoryItem:
	var item_definition: Item= GameData.get_item_definition(data["item"])
	var count: int= data["count"]
	return InventoryItem.new(item_definition, count)
