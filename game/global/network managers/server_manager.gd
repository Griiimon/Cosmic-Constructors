extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)
signal resume_game

const BASE_PLAYER_SCENE= preload("res://game/core/player/base_player.tscn")

var player_states: Dictionary
var ticks: int
var player_instances: Dictionary
var player_data: Dictionary

var control_movement_requests: Dictionary

var sync_vars: Array[SyncVar]



func _ready() -> void:
	process_mode= PROCESS_MODE_ALWAYS
	set_physics_process(false)


func host(port: int, game_scene: PackedScene):
	print("Creating server on port ", port, " ..")
	var error= NetworkManager.enet_peer.create_server(port)
	if error != OK:
		prints("Couldnt create server", error)
		return
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(remove_player)

	prints("Hosting scene", game_scene.resource_path)
	get_tree().change_scene_to_packed.call_deferred(game_scene)


func _physics_process(_delta: float) -> void:
	var world: World= Global.game.world
	
	if ticks % 3 == 0:
		var world_state: Dictionary
		WorldSyncState.add_player_states(world_state, player_states.values())
		WorldSyncState.add_grid_states(world_state, get_grid_states())
		WorldSyncState.add_sync_vars(world_state, serialize_sync_vars())
		WorldSyncState.add_objects(world_state, get_object_states())
		
		ClientManager.receive_world_state.rpc(world_state)

	for grid_id: int in control_movement_requests.keys():
		if not world.has_grid(grid_id): continue
		var request: Dictionary= control_movement_requests[grid_id]
		var grid: BlockGrid= world.get_grid(grid_id)

		var rotation_axis: Vector3= Vector3.UP
		var rotation_angle: float= 0
		var control_block: GridBlock= grid.get_block_local(request["control_block"])
		assert(control_block)
		var control_block_instance: BlockInstance= control_block.get_block_instance()
		rotation_axis= control_block_instance.basis.y
		rotation_angle= -control_block_instance.global_basis.z.angle_to(grid.basis.z)
	
		var arr: Array[int]= request["input"]
		var grid_move_vec:= Vector3(arr[1] - arr[0], arr[3] - arr[2], arr[5] - arr[4])
		
		DebugHud.send("Local Grid Move Vec", grid_move_vec)

		# TODO account for seat pitch, roll
		# yaw
		var global_grid_move_vec: Vector3= grid_move_vec.rotated(rotation_axis, rotation_angle)

		DebugHud.send("Grid Move Vec", global_grid_move_vec)

		grid.request_movement(grid_move_vec, global_grid_move_vec)

	for grid: BlockGrid in Global.game.world.get_grids():
		DebugHud.send(grid.name, Utils.get_short_vec3(grid.global_position))

	ticks+= 1


func peer_connected(id: int):
	print("Peer %d connected to server" % id)
	ClientManager.request_player_name.rpc_id(id)


@rpc("any_peer", "reliable")
func receive_player_name(player_name: String):
	print("Peer %d identified as %s" % [ get_sender_id(), player_name ])
	add_player(get_sender_id(), player_name)


func add_player(id: int, player_name: String):
	while Global.game.world.is_loading:
		print(" World still loading..")
		await get_tree().process_frame

	var data: Dictionary
	if player_data.has(player_name):
		data= player_data[player_name]
		ClientManager.receive_player_data.rpc_id(id, data)
		
	var player: BasePlayer= BASE_PLAYER_SCENE.instantiate()
	player.name= str(id)
	player.player_name= player_name
	Global.game.peers.add_child(player, true)
	player_instances[id]= player
	player_connected.emit(id)

	if Global.game.is_paused():
		await resume_game

	var world_state: Dictionary= WorldSyncState.build_initial_world_state(Global.game.world)
	ClientManager.receive_initial_world.rpc_id(id, Utils.compress_string(JSON.stringify(world_state)))

	Global.game.pause_execution(true)
	await resume_game
	Global.game.pause_execution(false)
	
	set_physics_process(true)


func remove_player(id: int):
	prints("Removing peer", id)
	player_disconnected.emit(id)


func get_grid_states()-> Array:
	var states: Array= []
	if Global.game:
		var world: World= Global.game.world
		if world:
			for grid in world.get_grids():
				states.append(GridSyncState.build_sync_state(grid))
	return states


func serialize_sync_vars()-> Array[Dictionary]:
	var result: Array[Dictionary]
	for sync_var in sync_vars:
		if not sync_var.requires_sync(): continue
		sync_var.synced()
		result.append(sync_var.serialize())
	return result


func get_object_states()-> Array:
	var states: Array= []
	if Global.game:
		var world: World= Global.game.world
		if world:
			for obj in world.get_objects():
				states.append(ObjectSyncState.build_sync_state(obj))
	return states


@rpc("any_peer", "reliable")
func request_game_scene():
	print("Requesting game scene")
	ClientManager.receive_game_scene.rpc_id(get_sender_id(), get_tree().current_scene.scene_file_path, ticks)


@rpc("any_peer", "reliable")
func request_spawn():
	ClientManager.spawn.rpc_id(get_sender_id())


@rpc("any_peer", "reliable")
func request_resume():
	resume_game.emit()

	
@rpc("any_peer")
func receive_player_state(data: Dictionary):
	#prints("Server receive player state", data)
	var peer_id: int= NetworkManager.get_sender_id()
	var timestamp: int= PlayerSyncState.get_timestamp(data)

	if not player_states.has(peer_id) or PlayerSyncState.get_timestamp(player_states[peer_id]) < timestamp:
		player_states[peer_id]= data
	PlayerSyncState.add_peer_id(player_states[peer_id], peer_id)
	
	PlayerSyncState.parse_sync_state(player_instances[peer_id], data)


@rpc("any_peer", "reliable")
func receive_sync_event(type: int, args: Array):
	assert(NetworkManager.is_server)
	pre_process_sync_event(type, args, get_sender_id())
	broadcast_sync_event(type, args, get_sender_id())


func broadcast_sync_event(type: int, args: Array, sender_id: int= 1):
	assert(NetworkManager.is_server)
	ClientManager.receive_sync_event.rpc(type, args, sender_id)


#FIXME a lot of duplicate code shared with EventSyncState.process_event
func pre_process_sync_event(type: int, args: Array, sender_id: int):
	var world: World= Global.game.world
	
	match type:
		EventSyncState.Type.ADD_GRID:
			var position: Vector3= args[0]
			var rotation: Vector3= args[1]
			var block_size: float= args[2]
			var faction_id: int= args[4]
			var grid: BlockGrid= world.add_grid(position, rotation, block_size, world.get_faction(faction_id))
			var global_grid_id: int= grid.id
			var local_grid_id: int= args[3]
			if global_grid_id != local_grid_id:
				print("Mapping local grid id %d from peer %d to %d" % [local_grid_id, sender_id, global_grid_id]) 
				args[2]= global_grid_id
			ClientManager.update_grid_id.rpc_id(sender_id, global_grid_id, local_grid_id)

		EventSyncState.Type.ADD_BLOCK:
			assert(NetworkManager.is_server)
			var grid_id: int= args[0]
			var grid: BlockGrid= Global.game.world.get_grid(grid_id)
			var block_id: int= args[1]
			var block: Block= GameData.get_block(block_id)
			var local_pos: Vector3i= args[2]
			var block_rotation: Vector3i= args[3]
			grid.add_block(block, local_pos, block_rotation)

		EventSyncState.Type.REMOVE_BLOCK:
			assert(NetworkManager.is_server)
			var grid_id: int= args[0]
			var grid: BlockGrid= Global.game.world.get_grid(grid_id)
			var local_pos: Vector3i= args[1]
			var block: GridBlock= grid.get_block_local(local_pos).get_grid_block()
			block.destroy(grid)

		EventSyncState.Type.REMOVE_GRID:
			var grid_id: int= args[0]
			world.remove_grid(world.get_grid(grid_id))

		EventSyncState.Type.CHANGE_BLOCK_PROPERTY:
			EventSyncState.change_block_property(world, args)

		EventSyncState.Type.CHANGE_GRID_PROPERTY:
			var grid_id: int= args[0]
			var property: BlockGrid.Property= args[1]
			var value= args[2]
			world.get_grid(grid_id).change_property(property, value)



func serialize_players()-> Array[Dictionary]:
	ClientManager.request_player_save_data.rpc()
	# FIXME super hacky
	await get_tree().create_timer(1).timeout
	var result: Array[Dictionary]
	result.assign(player_data.values())
	return result


@rpc("any_peer", "reliable")
func receive_player_save_data(data: Dictionary):
	player_data["name"]= data


func set_player_data(data_arr: Array[Dictionary]):
	for data in data_arr:
		player_data[data.name]= data


@rpc("any_peer", "reliable")
func request_save(custom_world_name: String, project_folder_world: bool):
	Global.game.world.save_world(custom_world_name, project_folder_world)


@rpc("any_peer", "reliable")
func sync_grid_anchored_state(grid: BlockGrid):
	# DESYNC
	# FIXME send with timestamp: if multiple for same grid are send in short succession.. bad
	ClientManager.receive_grid_anchored_state.rpc(grid.id, grid.is_anchored)


@rpc("any_peer", "reliable")
func grid_control_movement_request(grid_id: int, control_block_pos: Vector3i, input_vec: Array[int]):
	var world: World= Global.game.world
	if not world.has_grid(grid_id): return
	var has_pressed_keys: bool= input_vec.any(func(x): return x == 1)

	if not control_movement_requests.has(grid_id):
		if not has_pressed_keys: return
		control_movement_requests[grid_id]= {}
		control_movement_requests[grid_id]["control_block"]= control_block_pos
		control_movement_requests[grid_id]["input"]= input_vec
	else:
		for i in ClientManager.CONTROL_INPUTS.size():
			if input_vec[i] == 0: continue
			var val: int= clampi(input_vec[i], 0, 1)
			control_movement_requests[grid_id]["input"][i]= val

	has_pressed_keys= control_movement_requests[grid_id]["input"].any(func(x): return x == 1)

	if not has_pressed_keys:
		control_movement_requests.erase(grid_id)
		DebugHud.send("Local Grid Move Vec", Vector3.ZERO)
		DebugHud.send("Grid Move Vec", Vector3.ZERO)


@rpc("any_peer", "reliable")
func grid_control_rotation_request(grid_id: int, rot_vec: Vector3):
	var world: World= Global.game.world
	if not world.has_grid(grid_id): return
	world.get_grid(grid_id).request_rotation(rot_vec)


@rpc("any_peer", "reliable")
func player_entered_seat(grid_id: int, seat_pos: Vector3i):
	var world: World= Global.game.world
	var player: BasePlayer= player_instances[get_sender_id()]
	if not world.has_grid(grid_id):
		ClientManager.force_exit_seat.rpc_id(get_sender_id())
		return
	var grid= world.get_grid(grid_id)
	var seat_block: GridBlock= grid.get_block_local(seat_pos)
	if not seat_block:
		ClientManager.force_exit_seat.rpc_id(get_sender_id())
		return
		
	player.put_in_seat(seat_block.get_block_instance())


@rpc("any_peer", "reliable")
func player_left_seat():
	var player: BasePlayer= player_instances[get_sender_id()]
	player.leave_seat()


@rpc("any_peer", "reliable")
func spawn_blueprint(compressed_data: PackedByteArray, position: Vector3, rotation: Vector3= Vector3.ZERO):
	var data: Array[Dictionary]
	var json:= JSON.new()
	if not json.parse(Utils.decompress_string(compressed_data)) == OK:
		push_error("Error parsing Blueprint ", json.get_error_message(), json.get_error_line())
		return
		
	data.assign(json.data)
	var world: World= Global.game.world
	var blueprint_data:= BlueprintData.new()
	blueprint_data.position= position
	blueprint_data.rotation= rotation
	blueprint_data.load_blueprint(data, false, world)
	var grids: Array[BlockGrid]= blueprint_data.place(world)

	var grid_data: Array[Dictionary]= []
	for grid in grids:
		grid_data.append(grid.serialize())
	
	var compressed_grid_data: PackedByteArray= Utils.compress_string(JSON.stringify(grid_data))
	ClientManager.receive_grids.rpc(compressed_grid_data)


@rpc("any_peer", "reliable")
func request_block_property(grid_id: int, block_pos: Vector3i, property_name: String):
	var world: World= Global.game.world
	if not world.has_grid(grid_id): return
	var grid: BlockGrid= world.get_grid(grid_id)
	if not grid.has_block(block_pos): return

	var block_instance: BlockInstance= grid.get_block_local(block_pos).get_block_instance()
	assert(block_instance)
	var property: BlockProperty= block_instance.get_property_by_display_name(property_name)
	assert(property)

	ClientManager.receive_sync_event.rpc_id(get_sender_id(), EventSyncState.Type.CHANGE_BLOCK_PROPERTY, [ grid_id, block_pos, property_name, property.get_variant() ], 1)


@rpc("any_peer", "reliable")
func run_block_instance_method(method_name: String, grid_id: int, block_pos: Vector3i, args: Array):
	var world: World= Global.game.world
	if not world.has_grid(grid_id): return
	var grid: BlockGrid= world.get_grid(grid_id)
	if not grid.has_block(block_pos): return
	var grid_block: GridBlock= grid.get_block_local(block_pos)
	var inst: BlockInstance= grid_block.get_block_instance()
	if not inst: return
	assert(inst.has_method(method_name))
	inst.callv(method_name, [grid, grid_block] + args)


func register_sync_var(sync_var: SyncVar):
	sync_vars.append(sync_var)


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
