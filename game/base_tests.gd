class_name Tests
extends Node

@export var remove_voxel_terrain:= false
@export var equip_item: HandItem
@export var load_world: bool= false
@export var project_folder_world: bool= true
@export var freeze_grids: bool= false
@export var custom_world_name: String= ""

@onready var game: Game= get_parent()

var player: Player
var default_block: Block

var collected_resources: Dictionary



func _ready() -> void:
	await game.ready
	
	if remove_voxel_terrain:
		var potential_terrains= game.find_children("*", "VoxelLodTerrain")
		var terrain: VoxelLodTerrain= potential_terrains[0]
		
		if terrain:
			terrain.queue_free()

	player= game.player

	default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")

	
	if equip_item:
		player.action_state_machine.idle_state.equip_hand_item(equip_item)

	if load_world:
		Global.game.world.load_world(custom_world_name, project_folder_world)


	player.world.freeze_grids(freeze_grids)

	on_start()


func on_start():
	pass


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
			elif event.keycode == KEY_F2:
				player.world.freeze_grids(false)
			elif event.keycode == KEY_F5:
				player.world.save_world(custom_world_name, project_folder_world)

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
					
					SignalManager.build_block_changed.emit(build_state.current_block)


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
				grid.get_block_from_global_pos(collision_point).destroy(grid)


func spawn_plain_grid(pos: Vector3, size: Vector2i, centered: bool= true):
	var grid: BlockGrid= Global.game.world.add_grid(pos)
	
	for x in size.x:
		for z in size.y:
			grid.add_block(default_block, Vector3i(x, 0, z) - Vector3i(size.x / 2, 0, size.y / 2) / 2)
	
	