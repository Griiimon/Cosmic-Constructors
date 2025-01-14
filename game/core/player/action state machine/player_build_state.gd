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

var grid: BlockGrid
var local_block_pos: Vector3i
var block_rotation: Vector3i
var hotbar_layout:= HotbarLayout.new()



func on_enter():
	player.build_raycast.enabled= true
	player.build_raycast.target_position.z= -build_range
	
	if current_block:
		init_ghost(current_block.get_model())

	Global.ui.switch_hotbar(hotbar_layout)


func on_exit():
	remove_ghost()
	Global.ui.switch_hotbar(player.tool_hotbar)


func on_physics_process(delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("build"):
		finished.emit()
		return
	
	if not ghost: return

	if not align_ghost():
		return

	rotate_ghost(delta)

	if Input.is_action_just_pressed("build_block"):
		build_block()
		return
	elif Input.is_action_just_pressed("pick_block"):
		pick_block()
		return


	ghost.show()


func align_ghost():
	var raycast: RayCast3D= player.build_raycast

	if raycast.is_colliding():
		var collision_pos: Vector3= Utils.get_raycast_outside_collision_point(raycast)
		
		var old_grid: BlockGrid= grid
		grid= raycast.get_collider()
		assert(grid != null)

		var can_place:= false
		
		for i in build_range:
			if grid.can_place_block_at_global(current_block, collision_pos, block_rotation):
				can_place= true
				break
				
			collision_pos+= raycast.global_basis.z

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
		grid= player.world.add_grid(ghost.position, ghost.global_rotation)
		local_block_pos= Vector3i.ZERO
		
		#var query:= PhysicsShapeQueryParameters3D.new()
		#query.collision_mask= CollisionLayers.TERRAIN
		#query.shape= BoxShape3D.new()
		#query.transform= ghost.transform
		#
		#if player.get_world_3d().direct_space_state.intersect_shape(query):
			#grid.freeze= true
		
	grid.add_block(current_block, local_block_pos, Vector3i.ZERO if new_grid else block_rotation)


func pick_block():
	var raycast: RayCast3D= player.build_raycast
	
	if raycast.is_colliding():
		var collision_pos: Vector3= Utils.get_raycast_inside_collision_point(raycast)
		
		grid= raycast.get_collider()
		assert(grid != null)
		
		var picked_grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_pos)
		if picked_grid_block:
			current_block= picked_grid_block.get_block_definition()


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
