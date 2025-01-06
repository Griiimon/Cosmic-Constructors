class_name PlayerGrabHandlesState
extends PlayerActionStateMachineState

var handles: HandlesInstance



func on_exit():
	handles.disconnect_joint()


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("block_interact"):
		finished.emit()
