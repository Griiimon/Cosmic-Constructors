class_name WorldSyncState

const KEY_PLAYERS= "players"
const KEY_GRIDS= "grids"



static func add_player_states(world_state: Dictionary, player_states: Array):
	world_state[KEY_PLAYERS]= player_states


static func parse_player_states(world_state: Dictionary)-> Array:
	return world_state[KEY_PLAYERS]


static func add_grid_states(world_state: Dictionary, grid_states: Array):
	world_state[KEY_GRIDS]= grid_states


static func parse_grid_states(world_state: Dictionary)-> Array:
	return world_state[KEY_GRIDS]
