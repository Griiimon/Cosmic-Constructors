class_name BaseSandbox
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

	if game.player:
		on_player_spawned()
	else:
		SignalManager.player_spawned.connect(on_player_spawned)


func on_player_spawned():
	player= game.player

	default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	
	if equip_item:
		player.equip_hand_item(equip_item)

	if load_world and NetworkManager.is_single_player:
		await get_tree().physics_frame
		# TODO
		#if Global.terrain:
			#while not Global.terrain.is_area_meshed(..):
				#await get_tree().physics_frame
		Global.game.world.load_world(custom_world_name, project_folder_world)

	if freeze_grids:
		player.world.freeze_grids(freeze_grids)

	on_start()


func on_start():
	pass


func _physics_process(_delta):
	if player:
		DebugHud.send("Gravity", "%.3f" % player.get_gravity().length())
		DebugHud.send("Velocity", "%.2f" % player.get_velocity().length())
		#DebugHud.send("Vel Vector", player.get_velocity())


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed: 
			if event.keycode == KEY_F1:
				spawn_pallet()
			elif event.keycode == KEY_F2:
				if not NetworkManager.is_client:
					player.world.freeze_grids(false)
			elif event.keycode == KEY_F3:
				if player:
					#player.wear_equipment(load("res://game/data/equipment/back/jetpack/atmospheric_jetpack.tres"))
					#player.play_animation("wave")
					sit_in_nearest_seat()
			elif event.keycode == KEY_F4:
				DebugPanel.toggle()
			elif event.keycode == KEY_F5:
				player.world.save_world(custom_world_name, project_folder_world)
			elif event.keycode == KEY_F9:
				get_tree().reload_current_scene.call_deferred()
				return

	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.shift_pressed:
					remove_grid()
				else:
					remove_block()


func spawn_plain_grid(pos: Vector3, size: Vector2i, centered: bool= true):
	var grid: BlockGrid= Global.game.world.add_grid(pos)
	
	for x in size.x:
		for z in size.y:
			@warning_ignore("narrowing_conversion")
			grid.add_block(default_block, Vector3i(x, 0, z) - Vector3i(size.x / 2.0, 0, size.y / 2.0) / 2)


func remove_block():
	if not player.action_state_machine.build_state.is_current_state():
		return

	var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
	#prints("Remove query", query.from, query.to)
	query.hit_back_faces= false
	query.hit_from_inside= false
	var result= player.get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider.collision_layer == CollisionLayers.GRID:
		var grid: BlockGrid= result.collider
		var collision_point: Vector3= result.position
		collision_point+= -player.build_raycast.global_basis.z * 0.05
		var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_point) 
		if not grid_block: return
		
		if NetworkManager.is_client:
			ClientManager.send_sync_event(EventSyncState.Type.REMOVE_BLOCK,\
			 [grid.id, grid_block.local_pos])
		else:
			grid_block.destroy(grid)


func remove_grid():
	if not player.action_state_machine.build_state.is_current_state():
		return

	var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
	#prints("Remove query", query.from, query.to)
	query.hit_back_faces= false
	query.hit_from_inside= false
	var result= player.get_world_3d().direct_space_state.intersect_ray(query)
	if result and (result.collider as CollisionObject3D).collision_layer == CollisionLayers.GRID:
		var grid: BlockGrid= result.collider
		grid.world.remove_grid(grid)


func sit_in_nearest_seat():
	for grid: BlockGrid in player.world.grids.get_children():
		for block: BaseGridBlock in grid.get_blocks():
			if block.get_block_definition() is SeatBlock:
				player.sit(block.get_block_instance())
				return


func spawn_pallet():
	var pallet: Pallet= load("res://game/data/object entities/wooden_pallet.tscn").instantiate()
	pallet.position= player.global_position + player.get_look_vec() + Vector3.UP
	player.world.add_child(pallet)
