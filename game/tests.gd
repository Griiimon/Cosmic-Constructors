extends Node



func _ready() -> void:
	var default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	var grid:= BlockGrid.new()
	grid.position.z= -2
	grid.add_block(default_block, Vector3i.ZERO)
	add_child(grid)
