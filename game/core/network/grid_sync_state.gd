class_name GridSyncState

const KEY_ID = "id"
const KEY_POSITION = "pos"
const KEY_ROTATION = "rot"
const KEY_TIMESTAMP = "time"



static func build_sync_state(grid: BaseBlockGrid)-> Dictionary:
	var data: Dictionary
	data[KEY_ID]= grid.id
	data[KEY_POSITION]= grid.global_position
	data[KEY_ROTATION]= grid.global_rotation
	data[KEY_TIMESTAMP]= ServerManager.ticks
	return data


static func parse_sync_state(grid: BaseBlockGrid, data: Dictionary):
	grid.global_position= data[KEY_POSITION]
	grid.global_rotation= data[KEY_ROTATION]


static func get_grid_id(data: Dictionary)-> int:
	return data[KEY_ID]


static func get_position(data: Dictionary)-> Vector3:
	return data[KEY_POSITION]


static func get_rotation(data: Dictionary)-> Vector3:
	return data[KEY_ROTATION]


static func get_timestamp(data: Dictionary)-> int:
	return data[KEY_TIMESTAMP]
