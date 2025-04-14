class_name PlayerGridControlState
extends PlayerBaseControlState

var controlled_grid: BlockGrid
var control_block: GridBlock
var control_instance: GridControlInstance



func on_enter():
	player.action_state_machine.paused= true
	Global.ui.switch_hotbar(control_instance.hotbar_layout)


func on_exit():
	Global.ui.switch_hotbar(player.tool_hotbar)
	player.action_state_machine.paused= false


func on_physics_process(_delta: float):
	control_logic(control_instance, control_block)


func on_unhandled_input(event: InputEvent):
	if is_equipment_port_connection():
		if event.is_action_pressed("toggle_equipment"):
			get_viewport().set_input_as_handled()
			SignalManager.player_use_equipment.emit(false)
			finished.emit()
			return
		elif event.is_action_pressed("toggle_equipment_port"):
			player.toggle_equipment_port()
			finished.emit()
			return
	

func is_equipment_port_connection()-> bool:
	return true


func get_grid()-> BlockGrid:
	return controlled_grid
