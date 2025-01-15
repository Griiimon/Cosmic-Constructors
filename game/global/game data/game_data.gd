extends Node


@export var block_library: BlockLibrary
@export var scene_library: SceneLibrary
@export var fluid_library: FluidLibrary
@export var game_settings: GameSettings

var block_definition_lookup: Dictionary
var fluid_definition_lookup: Dictionary



func _ready() -> void:
	for block in block_library.blocks:
		block_definition_lookup[block.get_display_name()]= block

	for fluid in fluid_library.fluids:
		fluid_definition_lookup[fluid.get_display_name()]= fluid


func get_block_definition(block_name: String)-> Block:
	assert(block_definition_lookup.has(block_name))
	return block_definition_lookup[block_name]


func get_fluid_definition(fluid_name: String)-> Fluid:
	assert(fluid_definition_lookup.has(fluid_name))
	return fluid_definition_lookup[fluid_name]
