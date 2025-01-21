class_name EventSyncState

enum Type { START_PLAYER_ANIMATION, RESET_PLAYER_ANIMATION, WEAR_EQUIPMENT, CLEAR_EQUIPMENT_SLOT, EQUIP_HAND_ITEM, ADD_GRID, ADD_BLOCK, REMOVE_BLOCK }



static func process_event(type: Type, args: Array, peer_id: int):
	if not Global.game: return
	if not Global.game.world: return
	var world: World= Global.game.world
	
	var player: BasePlayer= null
	
	if peer_id != NetworkManager.peer_id:
		player= Global.game.get_peer(peer_id)
		
		if not player: 
			# TODO how would this happen?
			push_warning("EventSyncState peer %d doesnt know about %d" % [NetworkManager.peer_id, peer_id])
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
			#FIXME multiple players creating grids simultaneously may lead to wrong order
			world.add_grid(args[0], args[1])
		Type.ADD_BLOCK:
			var grid: BlockGrid= Global.game.world.get_grid(args[0])
			var block: Block= GameData.get_block(args[1])
			grid.add_block(block, args[2], args[3])
		Type.REMOVE_BLOCK:
			var grid: BlockGrid= Global.game.world.get_grid(args[0])
			var local_pos: Vector3i= args[1]
			grid.get_block_local(local_pos).destroy(grid)


static func can_sender_process_event(type: Type)-> bool:
	match type:
		Type.ADD_BLOCK, Type.REMOVE_BLOCK:
			return true
	return false
