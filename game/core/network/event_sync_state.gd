class_name EventSyncState

enum Type { START_PLAYER_ANIMATION, RESET_PLAYER_ANIMATION, WEAR_EQUIPMENT, CLEAR_EQUIPMENT_SLOT, EQUIP_HAND_ITEM, ADD_GRID, ADD_BLOCK, REMOVE_BLOCK, REMOVE_GRID, CHANGE_BLOCK_PROPERTY, CHANGE_GRID_PROPERTY }



#FIXME a lot of duplicate code shared with ServerManager.pre_process_sync_event
static func process_event(type: Type, args: Array, peer_id: int):
	if not Global.game: return
	if not Global.game.world: return
	assert(NetworkManager.is_client)
	
	var world: World= Global.game.world
	var player: BasePlayer= null
	
	if peer_id != 1 and peer_id != NetworkManager.peer_id:
		player= Global.game.get_peer(peer_id)
		
		if not player: 
			# FIXME is this something to worry about?
			push_warning("EventSyncState peer %d doesnt know about %d" % [NetworkManager.peer_id, peer_id])
			#breakpoint
			return

	
	match type:
		Type.START_PLAYER_ANIMATION:
			assert(args[0] is String)
			player.play_animation(args[0])

		Type.RESET_PLAYER_ANIMATION:
			player.reset_animation()

		Type.WEAR_EQUIPMENT:
			assert(args[0] is String)
			player.wear_equipment(load(args[0]))

		Type.CLEAR_EQUIPMENT_SLOT:
			pass

		Type.ADD_GRID:
			var position: Vector3= args[0]
			var rotation: Vector3= args[1]
			var grid_id: int= args[2]
			var grid: BlockGrid= world.add_grid(position, rotation)
			world.assign_grid_id(grid, false, grid_id, false)
			
		Type.ADD_BLOCK:
			var grid_id: int= args[0]
			var grid: BlockGrid= Global.game.world.get_grid(grid_id)
			var block_id: int= args[1]
			var block: Block= GameData.get_block(block_id)
			var local_pos: Vector3i= args[2]
			var block_rotation: Vector3i= args[3]
			grid.add_block(block, local_pos, block_rotation)

		Type.REMOVE_BLOCK:
			var grid_id: int= args[0]
			var grid: BlockGrid= Global.game.world.get_grid(grid_id)
			var local_pos: Vector3i= args[1]
			grid.get_block_local(local_pos).destroy(grid)

		Type.REMOVE_GRID:
			var grid_id: int= args[0]
			world.remove_grid(world.get_grid(grid_id))

		Type.CHANGE_BLOCK_PROPERTY:
			change_block_property(world, args)

		Type.CHANGE_GRID_PROPERTY:
			var grid_id: int= args[0]
			var property: BlockGrid.Property= args[1]
			var value= args[2]
			world.get_grid(grid_id).change_property(property, value)


static func change_block_property(world: World, args: Array):
	var grid_id: int= args[0]
	var local_pos: Vector3i= args[1]
	var property_name: String= args[2]
	var new_value= args[3]

	if not world.has_grid(grid_id): return
	var grid: BlockGrid= world.get_grid(grid_id)
	var grid_block: GridBlock= grid.get_block_local(local_pos)
	if not grid_block: return
	var block_instance: BlockInstance= grid_block.get_block_instance()
	assert(block_instance)
	assert(block_instance.property_table.has(property_name))
	var property: BlockProperty= block_instance.get_property_by_display_name(property_name)
	property.set_variant(grid, grid_block, new_value, false)
	if NetworkManager.is_client:
		property.on_client_sync(grid, grid_block)


static func can_sender_process_event(type: Type)-> bool:
	match type:
		Type.ADD_BLOCK, Type.REMOVE_BLOCK, Type.CHANGE_GRID_PROPERTY:
			return true
	return false
