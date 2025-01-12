extends Node

@export var default_build_hotbar_layout: Array[Block]
@export var infinite_furnace_ingredients: bool= false



func _ready() -> void:
	if not is_enabled(): return
	SignalManager.player_spawned.connect(on_player_spawned)


func on_player_spawned():
	var hotbar: HotbarLayout= Global.player.action_state_machine.build_state.hotbar_layout
	var ctr:= 1
	for block in default_build_hotbar_layout:
		hotbar.assign(HotkeyAssignmentBuildBlock.new(ctr, block))
		ctr+= 1

func is_enabled()-> bool:
	return true
