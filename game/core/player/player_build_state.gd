class_name PlayerBuildState
extends PlayerStateMachineState

@export var build_range: float= 4.0
@export var current_block: Block:
	set(b):
		current_block= b
		if not is_inside_tree(): return
		init_ghost()

var ghost: Node3D
var block_rotation: Vector3



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
	
	for child in ghost.find_children("*"):
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
				new_material.albedo_color= Color.WHITE
				new_material.albedo_texture= null
				
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


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("build"):
		finished.emit()
		return
	
	if not ghost: return

	var grid: BlockGrid
	var local_block_pos: Vector3i
	
	var raycast: RayCast3D= player.build_raycast
	if raycast.is_colliding():
		var collision_pos: Vector3= raycast.get_collision_point()
		collision_pos+= raycast.global_basis.z * 0.05
		
		grid= raycast.get_collider()
		assert(grid != null)
		
		local_block_pos= grid.get_local_grid_pos(collision_pos)
		var global_block_pos: Vector3= grid.get_global_block_pos(local_block_pos)
		ghost.position= global_block_pos
		ghost.rotation= grid.global_rotation
	else:
		ghost.position= player.to_global(raycast.target_position)
		ghost.rotation= player.global_rotation
	
	if Input.is_action_just_pressed("build_block"):
		if not grid:
			grid= player.world.add_grid(ghost.position, ghost.rotation)
			
			var query:= PhysicsShapeQueryParameters3D.new()
			query.collision_mask= Global.TERRAIN_COLLISION_LAYER
			query.shape= BoxShape3D.new()
			query.transform= ghost.transform
			
			if player.get_world_3d().direct_space_state.intersect_shape(query):
				grid.freeze= true
			
			
		grid.add_block(current_block, local_block_pos, block_rotation)
	else:
		if Input.is_action_just_pressed("rotate_block_left"):
			block_rotation.y-= 1
		elif Input.is_action_just_pressed("rotate_block_right"):
			block_rotation.y+= 1
		if Input.is_action_just_pressed("rotate_block_up"):
			block_rotation.x-= 1
		elif Input.is_action_just_pressed("rotate_block_down"):
			block_rotation.x+= 1
		if Input.is_action_just_pressed("roll_block_left"):
			block_rotation.z-= 1
		elif Input.is_action_just_pressed("roll_block_right"):
			block_rotation.z+= 1
		
	ghost.basis= ghost.basis * Basis.from_euler(block_rotation * deg_to_rad(90))
	ghost.show()
	#else:
		#ghost.hide()
