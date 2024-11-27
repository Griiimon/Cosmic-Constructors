class_name EventSyncState

enum Type { START_PLAYER_ANIMATION, RESET_PLAYER_ANIMATION, WEAR_EQUIPMENT, CLEAR_EQUIPMENT_SLOT, EQUIP_HAND_ITEM }



static func process_event(type: Type, args: Array, peer_id: int):
	if not Global.game: return
	
	var player: BasePlayer= Global.game.get_peer(peer_id)
	
	if not player: return
	
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
