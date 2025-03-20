class_name PlayerActionIdleState
extends PlayerActionStateMachineState

signal build_block
signal build_peripheral_entity



func on_enter():
	player.block_interact_shapecast.enabled= true
	player.item_interact_shapecast.enabled= true
	player.hand_item_container.show()


func on_exit():
	player.block_interact_shapecast.enabled= false
	player.item_interact_shapecast.enabled= false
	player.hand_item_container.hide()


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("build"):
		if Input.is_action_pressed("peripheral_entity_modifier"):
			build_peripheral_entity.emit()
		else:
			build_block.emit()
		return

	var block_interact_shapecast: ShapeCast3D= player.block_interact_shapecast
	
	CustomShapeCast.pierce_blocks(block_interact_shapecast, interactive_block_shapecast_filter)

	var grid: BlockGrid= CustomShapeCast.grid
	var grid_block: BaseGridBlock= CustomShapeCast.grid_block
	
	if block_interact_shapecast.is_colliding():
		if grid_block and grid_block.get_block_instance():
			if Input.is_action_pressed("open_block_property_panel"):
				SignalManager.interact_with_block.emit(grid_block.get_grid_block(), grid, player)
				return

	if Input.is_action_just_pressed("toggle_block_property") or Input.is_action_just_pressed("toggle_block_alt_property"):
		if block_interact_shapecast.is_colliding():
			if grid_block:
				var block_instance: BlockInstance= grid_block.get_block_instance()
				if block_instance:
					var property: BlockProperty= block_instance.default_interaction_property if Input.is_action_just_pressed("toggle_block_property")\
												 else block_instance.alternative_interaction_property

					if property:
						property.toggle(grid, grid_block)
						SignalManager.block_property_changed.emit(property)
						return

	interaction_logic()


func on_unhandled_input(event: InputEvent):
	var hand_item: HandItem= player.get_hand_item()
	if hand_item:
		var hand_object: HandObject= player.hand_object

		if event.is_action_pressed("use_item_primary"):
			if hand_item.primary_use_continuous:
				hand_object.start_using()
			else:
				# FIXME this wont be called
				hand_object.use()
			return
					
		elif event.is_action_released("use_item_primary"):
			if hand_item.primary_use_continuous:
				hand_object.stop_using()
				return
	
	if event.is_action_pressed("blueprint"):
		var ray_query:= PhysicsRayQueryParameters3D.create(player.head.global_position,\
		 	player.head.global_position + player.get_look_vec() * 20, CollisionLayers.GRID)
		var result: Dictionary= player.get_world_3d().direct_space_state.intersect_ray(ray_query)
		
		if result and result.collider:
			player.action_state_machine.save_blueprint(result.collider)
		else:
			player.action_state_machine.load_blueprint()


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
		var terrain: MyTerrain= MyTerrain.get_terrain(shapecast.get_collider(0))
		var local_pos: Vector3i= terrain.terrain_node.to_local(shapecast.get_collision_point(0))
		var radius: float= 1.5
		
		terrain.mine(local_pos, radius, true, shapecast.get_collision_point(0) + shapecast.global_basis.z * 0.5, shapecast.global_basis.z)


func interactive_block_shapecast_filter()-> bool:
	return not CustomShapeCast.grid_block.get_block_instance() or not CustomShapeCast.grid_block.get_block_instance().has_property_viewer()
