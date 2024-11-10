extends Node

@export var remove_asteroid:= false

@onready var game: Game= get_parent()

var player: Player

var collected_resources: Dictionary



func _ready() -> void:
	await game.ready
	if remove_asteroid:
		game.get_node("Asteroid").queue_free()

	player= game.player
	
	var default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	var grid:= BlockGrid.new()
	grid.position.z= -2
	grid.position.y= -3
	
	for x in 4:
		for z in 7:
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
				var local_pos: Vector3i= terrain.to_local($"../Player".global_position)
				#var local_pos: Vector3i= $"../Player".global_position
				var radius: float= 5
				VoxelUtils.pre_mine(terrain, local_pos, radius)
				
				var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
				tool.channel= VoxelBuffer.CHANNEL_SDF
				tool.mode= VoxelTool.MODE_REMOVE
				tool.do_sphere(local_pos, radius)
				
				#await get_tree().create_timer(1).timeout

				var new_resources: Dictionary= VoxelUtils.mined(terrain, local_pos, radius)

				for key in new_resources.keys():
					if not collected_resources.has(key):
						collected_resources[key]= 0.0
					collected_resources[key]+= new_resources[key]
				
				DebugHud.send("Gold", collected_resources[1] if collected_resources.has(1) else 0.0)

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
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
			prints("Remove query", query.from, query.to)
			query.hit_back_faces= false
			query.hit_from_inside= false
			var result= player.get_world_3d().direct_space_state.intersect_ray(query)
			if result:
				var grid: BlockGrid= result.collider
				var collision_point: Vector3= result.position
				collision_point+= -player.build_raycast.global_basis.z * 0.05
				grid.remove_block(grid.get_block_from_global_pos(collision_point))
