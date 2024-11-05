extends Node



func _ready() -> void:
	var default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	var grid:= BlockGrid.new()
	grid.position.z= -2
	grid.position.y= -2
	
	for x in 4:
		for z in 4:
			grid.add_block(default_block, Vector3i(x, 0, z))

	add_child(grid)
	
	await get_tree().physics_frame


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F1:
			var terrain: VoxelLodTerrain= $"../Asteroid".get_child(0)
			var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
			tool.channel= VoxelBuffer.CHANNEL_SDF
			tool.mode= VoxelTool.MODE_REMOVE
			tool.do_sphere(terrain.to_local($"../Player".global_position), 2)
