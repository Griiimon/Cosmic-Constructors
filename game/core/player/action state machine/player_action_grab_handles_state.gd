class_name PlayerGrabHandlesState
extends PlayerActionStateMachineState

var handles: HandlesInstance



func on_enter():
	player.play_animation("steer")
	if not player.is_in_third_person():
		player.fps_arms.show()


func on_exit():
	handles.disconnect_joint()
	player.reset_animation()
	player.fps_arms.hide()
	

func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("block_interact"):
		finished.emit()


func on_enter_first_person():
	player.fps_arms.show()


func on_enter_third_person():
	player.fps_arms.hide()
