extends Node

@onready var game: Game= get_parent()

var player: Player



func _ready() -> void:
	await game.ready
	player= game.player
	
	var default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	var grid:= BlockGrid.new()
	grid.position.z= -2
	grid.position.y= -3
	
	for x in 4:
		for z in 4:
			grid.add_block(default_block, Vector3i(x, 0, z))

	var thruster_block= load("res://game/data/blocks/thruster/thruster_block.tres")
	for x in 4:
		grid.add_block(thruster_block, Vector3i(x, 1, 0), Vector3i(0, -x, 0))

	var seat_block= load("res://game/data/blocks/pilot seat/pilot_seat_block.tres")

	grid.add_block(seat_block, Vector3i(2, 1, 2))

	var gyro_block= load("res://game/data/blocks/gyro/gyro_block.tres")
	
	grid.add_block(gyro_block, Vector3i(0, 1, 3))

	grid.inertial_dampeners= true
	
	Global.game.grids.add_child(grid)



func _physics_process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed: 
			if event.keycode == KEY_F1:
				var terrain: VoxelLodTerrain= $"../Asteroid".get_child(0)
				var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
				tool.channel= VoxelBuffer.CHANNEL_SDF
				tool.mode= VoxelTool.MODE_REMOVE
				tool.do_sphere(terrain.to_local($"../Player".global_position), 2)

			else:
				var switch_block: int= Input.get_axis("next_block", "previous_block")
				
				if switch_block:
					var build_state: PlayerBuildState= player.action_state_machine.build_state
					var blocks: Array[Block]= GameData.block_library.blocks
					var block_index= blocks.find(build_state.current_block)

					block_index= wrapi(block_index + switch_block, 0, blocks.size())
					build_state.current_block= blocks[block_index]

					while not build_state.current_block.can_be_built:
						block_index= wrapi(block_index + switch_block, 0, blocks.size())
						build_state.current_block= blocks[block_index]
