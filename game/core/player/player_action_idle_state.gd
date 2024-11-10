class_name PlayerActionIdleState
extends PlayerStateMachineState

signal build



func on_enter():
	player.block_interact_raycast.enabled= true


func on_exit():
	player.block_interact_raycast.enabled= false


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("build"):
		build.emit()
		return
	
	#if Input.is_action_pressed("block_interact"):
	if Input.is_action_just_pressed("toggle_block_property"):
		if player.block_interact_raycast.is_colliding():
			var raycast: RayCast3D= player.block_interact_raycast
			var grid: BlockGrid= raycast.get_collider()
			var collision_pos: Vector3= raycast.get_collision_point() - raycast.global_basis.z * 0.05
			var grid_block: GridBlock= grid.get_block_from_global_pos(collision_pos)
			if grid_block:
				var block_instance: BlockInstance= grid_block.get_block_instance()
				if block_instance:
					var default_property: BlockProperty= block_instance.default_interaction_property
					if default_property:
						#if Input.is_action_just_pressed("toggle_block_property"):
						default_property.toggle()
		return
	
	
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
					grid_block.get_block_instance().interact(grid, grid_block, player)
					return
