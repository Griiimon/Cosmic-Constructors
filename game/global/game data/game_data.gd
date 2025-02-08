extends Node

@export var block_library: BlockLibrary
@export var scene_library: SceneLibrary
@export var fluid_library: FluidLibrary
@export var item_library: ItemLibrary
@export var style_library: StyleLibrary
@export var game_settings: GameSettings

var block_definition_lookup: Dictionary
var fluid_definition_lookup: Dictionary
var item_definition_lookup: Dictionary
var block_categories: Dictionary



func init() -> void:
	var game_mode: GameMode= Global.game_mode
	if game_mode:
		block_library.blocks.append_array(game_mode.block_library.blocks)

	for block in block_library.blocks:
		block_definition_lookup[block.get_display_name()]= block
		if not block.category: continue
		if not block_categories.has(block.category):
			block_categories[block.category]= []
		block_categories[block.category].append(block)

	for fluid in fluid_library.fluids:
		fluid_definition_lookup[fluid.get_display_name()]= fluid

	for item in item_library.items:
		item_definition_lookup[item.get_display_name()]= item


func get_block_definition(block_name: String)-> Block:
	assert(block_definition_lookup.has(block_name))
	return block_definition_lookup[block_name]


func get_block(id: int)-> Block:
	return block_library.blocks[id]


func get_block_id(block: Block)-> int:
	return block_library.blocks.find(block)


func get_item_definition(item_name: String)-> Item:
	assert(item_definition_lookup.has(item_name))
	return item_definition_lookup[item_name]


func get_fluid_definition(fluid_name: String)-> Fluid:
	assert(fluid_definition_lookup.has(fluid_name))
	return fluid_definition_lookup[fluid_name]


func get_fluid(id: int)-> Fluid:
	return fluid_library.fluids[id]


func get_fluid_id(fluid: Fluid)-> int:
	return fluid_library.fluids.find(fluid)


func get_mouse_sensitivity()-> float:
	return game_settings.control_settings.mouse_sensitivity
