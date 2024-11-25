class_name BasePlayer
extends Entity



func parse_sync_state(data: Dictionary):
	global_position= data["position"]
	global_rotation= data["rotation"]
