class_name PlayerBuildState
extends PlayerActionStateMachineState


@export var build_range: float= 4.0
@export var smooth_rotation_speed: float= 2.0
@export var current_block: Block:
	set(b):
		current_block= b
		if not is_inside_tree(): return
		if current_block:
			init_ghost(current_block.get_model())


var block_list: Array[Block]
var block_index: int

var grid: BlockGrid
var block_size: float
var grid_size: Block.GridSize:
	set(s):
		grid_size= s
		block_size= Block.get_grid_size(grid_size)

var local_block_pos: Vector3i
var block_rotation: Vector3i
var hotbar_layout:= HotbarLayout.new()



func _ready() -> void:
	super()
	SignalManager.selected_block_category.connect(on_block_category_selected)

	grid_size= Block.GridSize.LARGE
	set_full_block_list()


func on_enter():
	player.build_raycast.enabled= true
	update_build_raycast_target_position()
	
	if current_block:
		init_ghost(current_block.get_model())

	Global.ui.switch_hotbar(hotbar_layout)


func on_exit():
	remove_ghost()
	Global.ui.switch_hotbar(player.tool_hotbar)
	SignalManager.canceled_build_mode.emit()
	

func on_physics_process(delta: float):
	if Input.is_action_just_pressed("build"):
		finished.emit()
		return

	if not ghost: return

	if not align_ghost():
		ghost.hide()
		return

	rotate_ghost(delta)

	if Input.is_action_just_pressed("toggle_block_categories"):
		SignalManager.toggle_block_category_panel.emit()
	elif Input.is_action_just_pressed("previous_block"):
		switch_block(-1)
		return
	elif Input.is_action_just_pressed("next_block"):
		switch_block(1)
		return
		
	ghost.show()


func on_unhandled_input(event: InputEvent):
	if event.is_action_pressed("build_block"):
		if ghost and ghost.visible:
			build_block()
			get_viewport().set_input_as_handled()
			return
	elif event.is_action_pressed("remove_grid"):
		remove_grid()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("remove_block"):
		remove_block()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			finished.emit()
		elif event.is_action_pressed("pick_block"):
			pick_block()
		elif event.is_action_pressed("align_block"):
			gravity_align_ghost()
		elif event.is_action_pressed("toggle_block_size"):
			grid_size= Block.GridSize.LARGE if grid_size == Block.GridSize.SMALL else Block.GridSize.SMALL
			update_build_raycast_target_position()
			on_block_category_selected(null)
		else:
			return
		get_viewport().set_input_as_handled()
	
	
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					switch_block(-1)
				MOUSE_BUTTON_WHEEL_DOWN:
					switch_block(1)


func align_ghost():
	var raycast: RayCast3D= player.build_raycast

	if raycast.is_colliding():
		var collision_pos: Vector3= Utils.get_raycast_outside_collision_point(raycast)
		
		var old_grid: BlockGrid= grid
		grid= raycast.get_collider()
		
		if not is_equal_approx(grid.block_size, Block.get_grid_size(grid_size)): return
		
		assert(grid != null)

		var can_place:= false
		
		for i in build_range:
			if grid.can_place_block_at_global(current_block, collision_pos, block_rotation):
				can_place= true
				break
				
			collision_pos+= raycast.global_basis.z * block_size

		if not can_place:
			if old_grid != grid:
				ghost.hide()
			return false
		
		local_block_pos= grid.get_local_grid_pos(collision_pos)
		var global_block_pos: Vector3= grid.get_global_block_pos(local_block_pos)
		ghost.position= global_block_pos
		ghost.rotation= grid.global_rotation
		
	else:
		grid= null
		#ghost.position= player.to_global(raycast.target_position)
		ghost.position= player.pivot.to_global(raycast.target_position)

	return true


func build_block():
	var new_grid:= false
	if not grid:
		new_grid= true
		grid= player.world.add_grid(ghost.position, ghost.global_rotation, block_size, player.faction)

		if NetworkManager.is_client:
			ClientManager.send_sync_event(EventSyncState.Type.ADD_GRID,\
				[ghost.position, ghost.global_rotation, grid.id, player.faction.id])
			grid.id_pending= true
			
		local_block_pos= Vector3i.ZERO
		
	var grid_block_rotation: Vector3i= Vector3i.ZERO if new_grid else block_rotation
	
	if NetworkManager.is_client:
		var stored_grid: BlockGrid= grid
		
		if grid.id_pending:
			await grid.id_assigned

		grid= stored_grid
		assert(grid)

		ClientManager.send_sync_event(EventSyncState.Type.ADD_BLOCK,\
		 [grid.id, GameData.get_block_id(current_block, block_size),\
			local_block_pos, grid_block_rotation])
	else:
		grid.add_block(current_block, local_block_pos, grid_block_rotation)

	var ignore_axis: int
	if Input.is_action_pressed("plane_fill"):
		if not grid.get_block_local(local_block_pos + Vector3i.UP) and not grid.get_block_local(local_block_pos + Vector3i.DOWN):
			ignore_axis= Vector3i.AXIS_Y
		elif not grid.get_block_local(local_block_pos + Vector3i.FORWARD) and not grid.get_block_local(local_block_pos + Vector3i.BACK):
			ignore_axis= Vector3i.AXIS_Z
		elif not grid.get_block_local(local_block_pos + Vector3i.LEFT) and not grid.get_block_local(local_block_pos + Vector3i.RIGHT):
			ignore_axis= Vector3i.AXIS_X
 
		plane_fill(local_block_pos, grid_block_rotation, ignore_axis)
		
	ghost.hide()


func pick_block():
	var raycast: RayCast3D= player.build_raycast
	
	if raycast.is_colliding():
		var collision_pos: Vector3= Utils.get_raycast_inside_collision_point(raycast)
		
		grid= raycast.get_collider()
		assert(grid != null)
		
		var picked_grid_block: GridBlock= grid.get_block_from_global_pos(collision_pos).get_grid_block()
		if picked_grid_block:
			current_block= picked_grid_block.get_block_definition()
			block_rotation= picked_grid_block.get_local_block_rotation()
			

func rotate_ghost(delta: float):
	var no_grid: bool= grid == null
	
	var old_rotation: Vector3i= block_rotation
	
	if rotation_input("rotate_block_left", no_grid):
		block_rotation.y-= 1
	elif rotation_input("rotate_block_right", no_grid):
		block_rotation.y+= 1
	if rotation_input("rotate_block_up", no_grid):
		block_rotation.x-= 1
	elif rotation_input("rotate_block_down", no_grid):
		block_rotation.x+= 1
	if rotation_input("roll_block_left", no_grid):
		block_rotation.z-= 1
	elif rotation_input("roll_block_right", no_grid):
		block_rotation.z+= 1
		
	if no_grid:
		ghost.rotation= player.pivot.global_rotation
		ghost.basis= ghost.basis * Basis.from_euler(block_rotation * delta * smooth_rotation_speed)
	else:
		if current_block.is_multi_block():
			if not grid.can_place_block_at_global(current_block, ghost.position, block_rotation):
				block_rotation= old_rotation
		ghost.basis= ghost.basis * Basis.from_euler(block_rotation * deg_to_rad(90))


func rotation_input(action_name: String, no_grid: bool)-> bool:
	if no_grid:
		return Input.is_action_pressed(action_name)
	else:
		return Input.is_action_just_pressed(action_name)


# TODO add safeguards
func plane_fill(block_pos: Vector3i, grid_block_rotation: Vector3i, ignore_axis: int):
	var occupied_positions: Array[Vector3i]= [block_pos]
	var position_list: Array[Vector3i]= [block_pos]
	
	while not position_list.is_empty():
		var current_pos: Vector3i= position_list.pop_front()
		for neighbor in grid.get_empty_block_neighbors(current_pos):
			if (neighbor - current_pos)[ignore_axis] != 0: continue
			if not neighbor in occupied_positions and not neighbor in position_list:
				if not grid.get_block_local(neighbor):
					position_list.append(neighbor)
					occupied_positions.append(neighbor)
					grid.add_block(current_block, neighbor, grid_block_rotation)


func switch_block(delta: int):
	if delta != 0:
		block_index= block_list.find(current_block)
	block_index= wrapi(block_index + delta, 0, block_list.size())
	current_block= block_list[block_index]

	while not current_block.can_be_built:
		block_index= wrapi(block_index + ( 1 if delta == 0 else delta), 0, block_list.size())
		current_block= block_list[block_index]
	
	SignalManager.build_block_changed.emit(current_block)


# align the ghost with up vector ( = -gravity )
func gravity_align_ghost():
	if not ghost: return

	#var trans: Transform3D= Utils.align_with_y(ghost.global_transform, -player.get_gravity().normalized())
	#var quat:= Quaternion(player.pivot.global_basis)
	
	# FIXME 
	#  make this work in accordance with rotate_ghost()
	#  absolutely no idea how

	#block_rotation= Vector3i.ZERO


func set_full_block_list():
	block_list= GameData.get_block_library(grid_size).blocks.duplicate()


func remove_block():
	var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
	query.hit_back_faces= false
	query.hit_from_inside= false
	var result= player.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and result.collider.collision_layer == CollisionLayers.GRID:
		var grid: BlockGrid= result.collider
		var collision_point: Vector3= Utils.get_raycast_inside_collision_point(player.build_raycast)
		#var collision_point: Vector3= result.position
		#collision_point+= -player.build_raycast.global_basis.z * 0.05
		var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_point) 
		if not grid_block: return
		
		grid_block= grid_block.get_grid_block()
		
		if NetworkManager.is_client:
			ClientManager.send_sync_event(EventSyncState.Type.REMOVE_BLOCK,\
			 [grid.id, grid_block.local_pos])
		else:
			grid_block.destroy(grid)


func remove_grid():
	var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
	query.hit_back_faces= false
	query.hit_from_inside= false
	var result= player.get_world_3d().direct_space_state.intersect_ray(query)
	if result and (result.collider as CollisionObject3D).collision_layer == CollisionLayers.GRID:
		var grid: BlockGrid= result.collider
		grid.world.remove_grid(grid)
		if NetworkManager.is_client:
			ClientManager.send_sync_event(EventSyncState.Type.REMOVE_GRID, [grid.id])


func update_build_raycast_target_position():
	player.build_raycast.target_position.z= -build_range * block_size


func on_block_category_selected(category: BlockCategory):
	assert(is_current_state())
	if category:
		block_list.assign(GameData.block_categories[category][block_size])
	else:
		set_full_block_list()
	block_index= 0
	switch_block(0)
