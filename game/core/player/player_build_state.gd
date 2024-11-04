class_name PlayerBuildState
extends PlayerStateMachineState

@export var build_range: float= 4.0
@export var current_block: Block

var ghost: Node3D


func on_enter():
	player.build_raycast.enabled= true
	player.build_raycast.target_position.z= -build_range
	
	init_ghost()


func on_exit():
	remove_child(ghost)
	ghost.queue_free()


func init_ghost():
	ghost= current_block.get_model()
	add_child(ghost)
	ghost.top_level= true
	ghost.hide()


func on_physics_process(_delta: float):
	var raycast: RayCast3D= player.build_raycast
	if raycast.is_colliding():
		var collision_pos: Vector3= raycast.get_collision_point()
		collision_pos+= raycast.global_basis.z * 0.05
		
		var grid: BlockGrid= raycast.get_collider()
		assert(grid != null)
		
		var local_block_pos: Vector3i= grid.get_local_grid_pos(collision_pos)
		var global_block_pos: Vector3= grid.get_global_block_pos(local_block_pos)
		ghost.position= global_block_pos
		ghost.rotation= grid.global_rotation
		ghost.show()
	else:
		ghost.hide()
		
