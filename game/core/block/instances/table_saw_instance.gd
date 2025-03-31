extends BlockInstance

@export var board_item: Item
@export var log_item: Item
@export var board_ratio: int= 4

@onready var item_catcher: ItemCatcher = $"Item Catcher"
@onready var item_ejector: ItemEjector= $"Item Ejector"



func _ready() -> void:
	super()
	item_catcher.caught_item.connect(on_item_caught)
	item_catcher.can_catch_callable= can_catch_item


func spawn_board():
	item_ejector.eject_item(InventoryItem.new(board_item, board_ratio), get_grid().world) 


func can_catch_item(inv_item: InventoryItem)-> bool:
	return inv_item.item == log_item


func on_item_caught(inv_item: InventoryItem):
	assert(inv_item.item == log_item)
	spawn_board()
