class_name StateMachineState
extends Node


signal state_entered
signal state_exited
signal finished



func on_enter():
	pass


func on_process(_delta: float):
	pass


func on_physics_process(_delta: float):
	pass


func on_always_physics_process(_delta: float):
	pass


func on_integrate_forces(_state: PhysicsDirectBodyState3D):
	pass


#func _input(event: InputEvent) -> void:
	#if is_current_state():
		#on_input(event)


func on_input(_event: InputEvent):
	pass


#func _unhandled_input(event: InputEvent) -> void:
	#if is_current_state():
		#on_unhandled_input(event)


func on_unhandled_input(_event: InputEvent):
	pass


func on_exit():
	pass


func cancel():
	get_state_machine().change_state(null)


func is_current_state() -> bool:
	return get_state_machine().current_state == self
	

func get_state_machine()-> FiniteStateMachine:
	return get_parent()
