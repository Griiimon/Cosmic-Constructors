class_name WorldSyncState

const KEY_PLAYERS= "players"
const KEY_GRIDS= "grids"
const KEY_VARS= "vars"
const KEY_OBJECTS= "objs"



static func add_player_states(world_state: Dictionary, player_states: Array):
	world_state[KEY_PLAYERS]= player_states


static func parse_player_states(world_state: Dictionary)-> Array:
	return world_state[KEY_PLAYERS]


static func add_grid_states(world_state: Dictionary, grid_states: Array):
	world_state[KEY_GRIDS]= grid_states


static func parse_grid_states(world_state: Dictionary)-> Array:
	return world_state[KEY_GRIDS]


static func add_sync_vars(world_state: Dictionary, sync_vars: Array):
	world_state[KEY_VARS]= sync_vars


static func parse_sync_vars(world_state: Dictionary)-> Array:
	return world_state[KEY_VARS]


static func add_objects(world_state: Dictionary, objects: Array):
	world_state[KEY_OBJECTS]= objects


static func parse_object_states(world_state: Dictionary)-> Array:
	return world_state[KEY_OBJECTS]


static func build_initial_world_state(world: World)-> Dictionary:
	var result: Dictionary
	result["grids"]= []
	result["players"]= []

	for grid: BaseBlockGrid in world.get_grids():
		result["grids"].append(grid.serialize())
	
	return result
