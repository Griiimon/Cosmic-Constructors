extends Node

const INTERPOLATION_OFFSET_TICKS= 10
const CONTROL_INPUTS= [ "strafe_left", "strafe_right", "sink", "rise", "move_forward", "move_back" ]

var ticks: int
var peer_states: Dictionary
var grid_states: Dictionary
var object_states: Dictionary
var sync_vars: Dictionary



func _ready() -> void:
	process_mode= PROCESS_MODE_ALWAYS
	set_physics_process(false)


func join(address: String, port: int):
	prints("Joining Server", address, " on port ", port, " ...")
	
	var error= NetworkManager.enet_peer.create_client(address, port)
	if error != OK:
		prints(" Joining failed:", error)
		return
	print(" Client created")
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer

	multiplayer.connected_to_server.connect(start_game)
	multiplayer.connection_failed.connect(connection_failed.bind("Connection failed"))
	multiplayer.server_disconnected.connect(get_tree().quit)
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if Global.game:
		if Global.player:
			ServerManager.receive_player_state.rpc_id(1, PlayerSyncState.build_sync_state(Global.player))
			
			for peer: BasePlayer in Global.game.peers.get_children():
				update_peer_node(peer)
		
			for grid: BlockGrid in Global.game.world.get_grids():
				update_grid(grid)

			for obj: ObjectEntity in Global.game.world.get_objects():
				update_object(obj)
				DebugHud.send("Object update", ticks)

	ticks+= 1


func start_game():
	print("Connection successful")
	NetworkManager.peer_id= multiplayer.get_unique_id()
	ServerManager.request_game_scene.rpc_id(1)


func connection_failed(s: String):
	prints("Connection failed:", s)


func store_peer_state(peer_state: Dictionary):
	var peer_id: int= PlayerSyncState.get_peer_id(peer_state)
	if not peer_states.has(peer_id):
		peer_states[peer_id]= [peer_state]
	else:
		var arr: Array= peer_states[peer_id]
		var this_timestamp: int= PlayerSyncState.get_timestamp(peer_state)
		var last_timestamp: int= PlayerSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(peer_state)


func update_peer_node(player: BasePlayer):
	var peer_id: int= int(str(player.name))
	assert(peer_states.has(peer_id))
	var arr: Array= peer_states[peer_id]
	if arr.size() == 1:
		PlayerSyncState.parse_sync_state(player, arr[0])
		return
	
	var interpolation_result: Array= calculate_interpolation(arr, PlayerSyncState.get_timestamp)
	var past_state: Dictionary= interpolation_result[0]
	var future_state: Dictionary= interpolation_result[1]
	var interpolation_factor: float= interpolation_result[2]

	var smooth:= 0.5
	
	player.global_position= interpolate_position(player.global_position, PlayerSyncState.get_position(past_state),\
				PlayerSyncState.get_position(future_state), interpolation_factor, smooth)
	
	player.global_basis= interpolate_basis(player.global_basis, PlayerSyncState.get_rotation(past_state),\
				PlayerSyncState.get_rotation(future_state), interpolation_factor, smooth)


func store_grid_state(grid_state: Dictionary):
	var grid_id: int= GridSyncState.get_grid_id(grid_state)
	if not grid_states.has(grid_id):
		grid_states[grid_id]= [grid_state]
	else:
		var arr: Array= grid_states[grid_id]
		var this_timestamp: int= GridSyncState.get_timestamp(grid_state)
		var last_timestamp: int= GridSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(grid_state)


func update_grid(grid: BlockGrid):
	var grid_id: int= grid.id
	if grid.id_pending: return
	
	if not grid_states.has(grid_id):
		return
	
	var arr: Array= grid_states[grid_id]
	if arr.size() == 1:
		GridSyncState.parse_sync_state(grid, arr[0])
		return
	
	var interpolation_result: Array= calculate_interpolation(arr, GridSyncState.get_timestamp)
	var past_state: Dictionary= interpolation_result[0]
	var future_state: Dictionary= interpolation_result[1]
	var interpolation_factor: float= interpolation_result[2]

	var smooth:= 0.1
	
	grid.global_position= interpolate_position(grid.global_position, GridSyncState.get_position(past_state),\
				GridSyncState.get_position(future_state), interpolation_factor, smooth)
	
	grid.global_basis= interpolate_basis(grid.global_basis, GridSyncState.get_rotation(past_state),\
				GridSyncState.get_rotation(future_state), interpolation_factor, smooth)


func store_object_state(object_state: Dictionary):
	var object_id: int= ObjectSyncState.get_object_id(object_state)
	if not object_states.has(object_id):
		object_states[object_id]= [object_state]
	else:
		var arr: Array= object_states[object_id]
		var this_timestamp: int= ObjectSyncState.get_timestamp(object_state)
		var last_timestamp: int= ObjectSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(object_state)


func update_object(object: ObjectEntity):
	var object_id: int= object.id
	
	if not object_states.has(object_id):
		return
	
	var arr: Array= object_states[object_id]
	if arr.size() == 1:
		ObjectSyncState.parse_sync_state(object, arr[0])
		return
	
	var interpolation_result: Array= calculate_interpolation(arr, ObjectSyncState.get_timestamp)
	var past_state: Dictionary= interpolation_result[0]
	var future_state: Dictionary= interpolation_result[1]
	var interpolation_factor: float= interpolation_result[2]

	var smooth:= 0.5
	
	object.global_position= interpolate_position(object.global_position, ObjectSyncState.get_position(past_state),\
				ObjectSyncState.get_position(future_state), interpolation_factor, smooth)

	object.global_basis= interpolate_basis(object.global_basis, ObjectSyncState.get_rotation(past_state),\
				ObjectSyncState.get_rotation(future_state), interpolation_factor, smooth)

	object.show()


func send_sync_event(type: int, args: Array= []):
	assert(NetworkManager.is_client)
	ServerManager.receive_sync_event.rpc_id(1, type, args)


func send_all_sync_events(receiver: int):
	assert(NetworkManager.is_client)
	var player: Player= Global.player
	if not player: return
	
	for equipment_object in player.active_equipment:
		receive_sync_event.rpc_id(receiver, EventSyncState.Type.WEAR_EQUIPMENT, [equipment_object.item.resource_path], NetworkManager.peer_id)


func request_resume():
	ServerManager.request_resume.rpc_id(1)


@rpc("any_peer", "reliable")
func receive_sync_event(type: int, args: Array, peer_id: int):
	if peer_id == NetworkManager.peer_id and not EventSyncState.can_sender_process_event(type):
		return
	EventSyncState.process_event(type, args, peer_id)


@rpc("any_peer", "reliable")
func receive_game_scene(scene_path: String, server_ticks: int):
	ticks= server_ticks
	prints("Running game scene", scene_path)
	get_tree().change_scene_to_file.call_deferred(scene_path)


@rpc("any_peer")
func receive_world_state(data: Dictionary):
	if not Global.game: return
	if not Global.player: return
	
	#prints("Client receive world state", data)
	
	var player_states: Array= WorldSyncState.parse_player_states(data)
	for peer_state: Dictionary in player_states:
		var peer_id: int= PlayerSyncState.get_peer_id(peer_state)
		if peer_id == NetworkManager.peer_id:
			continue
		
		var base_player: BasePlayer= Global.game.get_peer(peer_id)
		if not base_player:
			base_player= Global.game.add_peer(peer_state)
		
		store_peer_state(peer_state)

	var new_grid_states: Array= WorldSyncState.parse_grid_states(data)
	for grid_state: Dictionary in new_grid_states:
		store_grid_state(grid_state)

	var new_sync_vars: Array= WorldSyncState.parse_sync_vars(data)
	for sync_var_data in new_sync_vars:
		var sync_var= SyncVar.deserialize(sync_var_data)
		var hash: int= sync_var.get_hash()
		sync_vars[hash]= sync_var
		#prints("Received SyncVar", sync_var.get_as_text())

	var new_object_states: Array= WorldSyncState.parse_object_states(data)
	for object_state: Dictionary in new_object_states:
		store_object_state(object_state)


@rpc("any_peer", "reliable")
func receive_grids(compressed_data: PackedByteArray): 
	var json_str: String= Utils.decompress_string(compressed_data)
	var json:= JSON.new()
	
	if json.parse(json_str) != OK:
		push_error("Receive grids parse error", json.get_error_message(), json.get_error_line())
		return

	assert(Global.game.world)
	var world_grid_data: Dictionary
	
	for grid_data: Dictionary in json.data:
		var grid: BlockGrid= BlockGrid.pre_deserialize(grid_data, Global.game.world)
		world_grid_data[grid]= grid_data
		grid.freeze= true

	for grid: BlockGrid in world_grid_data.keys():
		grid.deserialize(world_grid_data[grid])


@rpc("any_peer", "reliable")
func spawn():
	Global.game.spawn_player()


@rpc("any_peer", "reliable")
func request_full_peer_sync():
	send_all_sync_events(get_sender_id())


@rpc("any_peer", "reliable")
func update_grid_id(global_grid_id: int, local_grid_id: int):
	var world: World= Global.game.world
	assert(world)
	var grid: BlockGrid= world.get_grid(local_grid_id)
	assert(grid)

	if global_grid_id != local_grid_id:
		world.assign_grid_id(grid, false, global_grid_id)
		print("Updating grid id from %d to %d" % [local_grid_id, global_grid_id])
	
	grid.id_pending= false
	grid.id_assigned.emit()


@rpc("any_peer", "reliable")
func receive_initial_world(compressed_json: PackedByteArray):
	var json_str: String= Utils.decompress_string(compressed_json)
	var json:= JSON.new()
	if json.parse(json_str) != OK:
		push_error("Can't parse JSON string ", json_str)
		breakpoint 
		return 
		
	var world_data: Dictionary= json.data
	prints("Client received world data", world_data)

	while not Global.game or not Global.game.world:
		await get_tree().process_frame
	
	Global.game.world.load_world(world_data)

	request_resume()


@rpc("any_peer", "reliable")
func request_player_save_data():
	if Global.player:
		ServerManager.receive_player_save_data.rpc_id(1, Global.player.serialize())


@rpc("any_peer", "reliable")
func request_player_name():
	ServerManager.receive_player_name.rpc_id(1, NetworkManager.player_name)


@rpc("any_peer", "reliable")
func receive_player_data(data: Dictionary):
	prints("%s received player data" % NetworkManager.player_name, data)
	while not Global.player:
		await get_tree().process_frame
	Global.player.deserialize(data)


@rpc("any_peer", "reliable")
func receive_grid_anchored_state(grid_id: int, anchored: bool):
	if not Global.game.world.has_grid(grid_id):
		push_warning("Peer %s received grid anchored state update for non-existing grid %d" % [ NetworkManager.peer_id, grid_id ])
		return
	Global.game.world.get_grid(grid_id).is_anchored= anchored


func collect_grid_control_inputs(grid_id: int, control_block_pos: Vector3i):
	var input_vec: Array[int]
	var requires_sync:= false
	
	for action: String in CONTROL_INPUTS:
		if Input.is_action_just_pressed(action):
			input_vec.append(1)
			requires_sync= true
		elif Input.is_action_just_released(action):
			input_vec.append(-1)
			requires_sync= true
		else:
			input_vec.append(0)

	if requires_sync:
		ServerManager.grid_control_movement_request.rpc_id(1, grid_id, control_block_pos, input_vec)


func force_exit_seat():
	if not Global.player: return
	var state_machine: PlayerMovementStateMachine= Global.player.movement_state_machine
	if not state_machine.seated_state.is_current_state():
		return
	
	state_machine.on_left_seat()


func calculate_interpolation(arr: Array, get_timestamp: Callable)-> Array:
	var render_tick: int= ticks - INTERPOLATION_OFFSET_TICKS
	
	while arr.size() > 2 and get_timestamp.call(arr[1]) < render_tick:
		arr.remove_at(0)

	var past_state: Dictionary= arr[0]
	var future_state: Dictionary= arr[1]
	
	var factor: float= (render_tick - get_timestamp.call(past_state)) / float(get_timestamp.call(future_state) - get_timestamp.call(past_state))
	factor= max(factor, 0)
	
	return [ past_state, future_state, factor ]


func interpolate_position(current_position: Vector3, past_position: Vector3, future_position: Vector3, factor: float, smooth: float)-> Vector3:
	var new_pos: Vector3= lerp(past_position, future_position, factor)
	return lerp(current_position, new_pos, 1 - smooth)


func interpolate_basis(basis: Basis, past_rotation: Vector3, future_rotation: Vector3, factor: float, smooth: float)-> Basis:
	var new_basis: Basis= Basis.from_euler(past_rotation).slerp(Basis.from_euler(future_rotation), factor)
	return basis.slerp(new_basis, 1 - smooth)


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()


func has_sync_var(hash: int)-> bool:
	return sync_vars.has(hash)


func get_sync_var_value(hash: int)-> Variant:
	return sync_vars[hash].get_value()
