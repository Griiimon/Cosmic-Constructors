class_name WorldSyncState

const KEY_PLAYERS= "players"



static func add_player_states(world_state: Dictionary, player_states: Dictionary):
	world_state[KEY_PLAYERS]= player_states
