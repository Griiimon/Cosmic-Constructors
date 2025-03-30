extends BlockInstance

@onready var ore_pile: OrePile = $"Ore Pile"
@onready var item_catcher: ItemCatcher = $"Item Catcher"



func _ready() -> void:
	super()
	item_catcher.caught_item.connect(on_item_caught)


func get_dynamic_mass(grid_block: GridBlock)-> int:
	return ore_pile.get_mass() + grid_block.get_block_definition().mass


func on_item_caught(inv_item: InventoryItem):
	assert(inv_item.item is RawMaterialItem)
	ore_pile.add_inv_item(inv_item)


func _on_ore_pile_updated() -> void:
	change_mass()


func can_item_catcher_catch_item(inv_item: InventoryItem)-> bool:
	return inv_item.item is RawMaterialItem and not ore_pile.is_full()
