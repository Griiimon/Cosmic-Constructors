class_name CnCStoreInstance
extends BlockInstance

@export var desc_text: String= "Buy.."
@export var max_count: int= 90


@onready var offered_item_count: BlockPropInt= BlockPropInt.new("Count").\
		read_only().on_sync(on_count_changed)

@onready var stack: Node3D = $Stack
@onready var desc_labels: Node3D = $"Desc Labels"

@onready var area: Area3D = $Area3D



func _ready() -> void:
	super()
	for label: Label3D in desc_labels.get_children():
		label.text= desc_text


func interact(grid: BaseBlockGrid, grid_block: GridBlock, player: Player):
	if player.faction != grid.faction: return
	run_server_method(buy, grid, grid_block, [ grid.faction.id if grid.faction else -1])


# TODO get faction from grid
func buy(grid: BaseBlockGrid, grid_block: GridBlock, faction_id: int):
	if offered_item_count.get_value_i() >= max_count: return
	var game: CastlesAndCannonsGame= Global.game
	var faction: Faction= game.world.get_faction(faction_id)
	if not faction: return
	var price: int= get_item_price()
	if not game.has_faction_money(faction, price): return
	offered_item_count.set_variant(grid, grid_block, offered_item_count.get_value_i() + 1)
	game.change_faction_money(faction, -price)
	fill_cannons(grid, grid_block)


func fill_cannons(grid: BaseBlockGrid, grid_block: GridBlock):
	var faction: Faction= get_grid().faction
	var cannons: Array[CnCCannonInstance]
	
	for other_area in area.get_overlapping_areas():
		var instance: BlockInstance= other_area.get_parent()
		assert(instance is CnCCannonInstance)
		if instance.get_grid().faction == faction:
			var cannon: CnCCannonInstance= instance
			cannons.append(cannon)
	
	cannons.sort_custom( func(a: CnCCannonInstance, b: CnCCannonInstance):\
			return a.projectiles.get_value_i() < b.projectiles.get_value_i() )

	var total_items: int= offered_item_count.get_value_i()
	while total_items > 0:
		for cannon in cannons:
			if cannon.projectiles.get_value_i() < cannon.projectiles.get_max_value():
				var cannon_grid: BaseBlockGrid= cannon.get_grid()
				var cannon_block: GridBlock= cannon_grid.get_block_from_global_pos(cannon.global_position)
				cannon.projectiles.set_variant(cannon_grid, cannon_block, cannon.projectiles.get_value_i() + 1)
				total_items-= 1
				
				if total_items == 0: break

	offered_item_count.set_variant_conditionally(grid, grid_block, total_items)


func on_count_changed(_grid: BaseBlockGrid= null, _grid_block: GridBlock= null):
	var comp: int= offered_item_count.get_value_i()
	for i in stack.get_child_count():
		var item: Node3D= stack.get_child(i)
		item.visible= comp > i


func get_item_price()-> int:
	assert(false, "Abstract method")
	return 0
