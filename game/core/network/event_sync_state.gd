class_name EventSyncState

enum Type { START_PLAYER_ANIMATION, RESET_PLAYER_ANIMATION, WEAR_EQUIPMENT, CLEAR_EQUIPMENT_SLOT }

#var type: Type
#var param: Variant


static func process_event(type: Type, param: Variant, peer_id: int):
	match type:
		Type.START_PLAYER_ANIMATION:
		Type.RESET_PLAYER_ANIMATION:
		Type.WEAR_EQUIPMENT:
		Type.CLEAR_EQUIPMENT_SLOT:
