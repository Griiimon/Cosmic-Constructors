extends Node

@export var active: DebugSettingsResource
@export var default: DebugSettingsResource



func _ready() -> void:
	if not is_enabled(): 
		active= default
		return
	
	SignalManager.player_spawned.connect(on_player_spawned)


func on_player_spawned(player: Player):
	var hotbar: HotbarLayout= player.action_state_machine.build_state.hotbar_layout
	var ctr:= 1
	for block in active.default_build_hotbar_layout:
		hotbar.assign(HotkeyAssignmentBuildBlock.new(ctr, block))
		ctr+= 1


func is_enabled()-> bool:
	return true
