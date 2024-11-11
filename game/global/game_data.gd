extends Node


@export var block_library: BlockLibrary


var block_definition_lookup: Dictionary



func _ready() -> void:
	for block in block_library.blocks:
		block_definition_lookup[block.get_display_name()]= block


func get_block_definition(block_name: String)-> Block:
	assert(block_definition_lookup.has(block_name))
	return block_definition_lookup[block_name]
