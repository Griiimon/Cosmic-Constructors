class_name PlayerBuildState
extends PlayerStateMachineState

@export var build_range: float= 4.0
@export var smooth_rotation_speed: float= 2.0
@export var current_block: Block:
	set(b):
		current_block= b
		if not is_inside_tree(): return
		init_ghost()

var ghost: Node3D
var grid: BlockGrid
var local_block_pos: Vector3i
var block_rotation: Vector3i



func on_enter():
	player.build_raycast.enabled= true
	player.build_raycast.target_position.z= -build_range
	
	init_ghost()


func on_exit():
	remove_ghost()
	

func init_ghost():
	if not current_block: return
	
	if ghost:
		remove_ghost()
		
	ghost= current_block.get_model()
	ghost.set_script(null)
	add_child(ghost)
	ghost.top_level= true
	
	var mesh_instances: Array= ghost.find_children("*")
	if ghost is MeshInstance3D:
		mesh_instances.append(ghost)
	
	for child in mesh_instances:
		if child is not MeshInstance3D:
			child.queue_free()
		else:
			var mesh_instance: MeshInstance3D= child
			var old_material: StandardMaterial3D= mesh_instance.mesh.surface_get_material(0)
			var new_material: StandardMaterial3D
			if not old_material:
				new_material= StandardMaterial3D.new()
			else:
				new_material= old_material.duplicate()
			
			new_material.albedo_color= Color.SKY_BLUE
			new_material.albedo_color.a= 0.7
				
			mesh_instance.mesh= mesh_instance.mesh.duplicate()
			mesh_instance.mesh.surface_set_material(0, new_material)
			
			#material.transparency= BaseMaterial3D.TRANSPARENCY_ALPHA
			#material.albedo_color.a= 0.8

	ghost.hide()


func remove_ghost():
	if not ghost: return
	remove_child(ghost)
	ghost.queue_free()
	ghost= null


func on_physics_process(delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("build"):
		finished.emit()
		return
	
	if not ghost: return

	if not align_ghost():
		return

	if Input.is_action_just_pressed("build_block"):
		build_block()
		return
	elif Input.is_action_just_pressed("pick_block"):
		pick_block()
		return

	rotate_ghost(delta)

	ghost.show()


func align_ghost():
	var raycast: RayCast3D= player.build_raycast

	if raycast.is_colliding():
		var collision_pos: Vector3= raycast.get_collision_point()
		collision_pos+= raycast.global_basis.z * 0.05
		
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
	if not grid:
		grid= player.world.add_grid(ghost.position, ghost.global_rotation)
		local_block_pos= Vector3i.ZERO
		
		var query:= PhysicsShapeQueryParameters3D.new()
		query.collision_mask= Global.TERRAIN_COLLISION_LAYER
		query.shape= BoxShape3D.new()
		query.transform= ghost.transform
		
		if player.get_world_3d().direct_space_state.intersect_shape(query):
			grid.freeze= true
		
	grid.add_block(current_block, local_block_pos, block_rotation)


func pick_block():
	var raycast: RayCast3D= player.build_raycast
	
	if raycast.is_colliding():
		var collision_pos: Vector3= raycast.get_collision_point()
		collision_pos-= raycast.global_basis.z * 0.05
		
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
