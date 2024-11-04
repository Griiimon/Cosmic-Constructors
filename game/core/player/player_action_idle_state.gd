class_name PlayerActionIdleState
extends PlayerStateMachineState



func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("interact"):
		var shapecast: ShapeCast3D= player.interact_shapecast
		if shapecast.is_colliding():
			var grid: BlockGrid= shapecast.get_collider(0)
			assert(grid)
			var collision_pos: Vector3= shapecast.get_collision_point(0)
			collision_pos-= shapecast.global_basis.z * 0.01
			
			var grid_block: GridBlock= grid.get_block_from_global_pos(collision_pos)
			if grid_block:
				if grid_block.block_definition.can_interact():
					grid_block.block_instance.interact(grid, grid_block, player)
