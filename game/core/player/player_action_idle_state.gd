class_name PlayerActionIdleState
extends PlayerStateMachineState

signal build



func on_enter():
	player.block_interact_raycast.enabled= true


func on_exit():
	player.block_interact_raycast.enabled= false


func on_physics_process(_delta: float):
	var hand_item: HandItem= player.get_hand_item()
	if hand_item:
		var hand_object: HandObject= player.hand_object

		if Input.is_action_pressed("use_item_primary"):
			if Input.is_action_just_pressed("use_item_primary"):
				if hand_item.primary_use_continuous:
					hand_object.start_using()
				else:
					hand_object.use()
				return
					
		elif Input.is_action_just_released("use_item_primary"):
			if hand_item.primary_use_continuous:
				hand_object.stop_using()
				return

	if Input.is_action_just_pressed("build"):
		build.emit()
		return
	
	#if Input.is_action_pressed("block_interact"):
	if Input.is_action_just_pressed("toggle_block_property") or Input.is_action_just_pressed("toggle_block_alt_property"):
		if player.block_interact_raycast.is_colliding():
			var raycast: RayCast3D= player.block_interact_raycast
			var grid: BlockGrid= raycast.get_collider()
			var collision_pos: Vector3= raycast.get_collision_point() - raycast.global_basis.z * 0.05
			var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_pos)
			if grid_block:
				var block_instance: BlockInstance= grid_block.get_block_instance()
				if block_instance:
					var property: BlockProperty= block_instance.default_interaction_property if Input.is_action_just_pressed("toggle_block_property")\
												 else block_instance.alternative_interaction_property

					if property:
						property.toggle()
						SignalManager.block_property_changed.emit(property)
						return
	
	
	if Input.is_action_just_pressed("interact"):
		var shapecast: ShapeCast3D= player.interact_shapecast
		if shapecast.is_colliding():
			var grid: BlockGrid= shapecast.get_collider(0)
			assert(grid)
			var collision_pos: Vector3= shapecast.get_collision_point(0)
			collision_pos-= shapecast.global_basis.z * 0.01
			
			var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_pos)
			if grid_block:
				if grid_block.get_block_definition().can_interact():
					grid_block.get_block_instance().interact(grid, grid_block, player)
					return


func equip_hand_item(hand_item: HandItem):
	force_unequip_item()
	player.hand_object= hand_item.scene.instantiate()
	player.hand_object.item_definition= hand_item
	player.hand_object.player= player
	player.hand_item_container.add_child(player.hand_object)


func force_unequip_item():
	if player.hand_item_container.get_child_count() > 0:
		player.hand_item_container.get_child(0).queue_free()
		player.hand_object= null


func drill():
	var shapecast: ShapeCast3D= player.drill_shapecast
	if shapecast.is_colliding():
		var terrain: VoxelLodTerrain= shapecast.get_collider(0)
		var local_pos: Vector3i= terrain.to_local(shapecast.get_collision_point(0))
		var radius: float= 2.0
		var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
		tool.channel= VoxelBuffer.CHANNEL_SDF
		tool.mode= VoxelTool.MODE_REMOVE
		tool.do_sphere(local_pos, radius)
