class_name PlayerSyncState

const KEY_PEER_ID = "id"
const KEY_POSITION = "pos"
const KEY_ROTATION = "rot"
const KEY_TIMESTAMP = "time"



static func build_sync_state(player: Player)-> Dictionary:
	var data: Dictionary
	data[KEY_POSITION]= player.global_position
	data[KEY_ROTATION]= player.global_rotation
	data[KEY_TIMESTAMP]= ClientManager.ticks
	return data


static func parse_sync_state(player: BasePlayer, data: Dictionary):
	player.global_position= data[KEY_POSITION]
	player.global_rotation= data[KEY_ROTATION]


static func add_peer_id(data: Dictionary, peer_id: int):
	data[KEY_PEER_ID]= peer_id


static func get_peer_id(data: Dictionary)-> int:
	return data[KEY_PEER_ID]


static func get_position(data: Dictionary)-> Vector3:
	return data[KEY_POSITION]


static func get_rotation(data: Dictionary)-> Vector3:
	return data[KEY_ROTATION]


static func get_timestamp(data: Dictionary)-> int:
	return data[KEY_TIMESTAMP]
