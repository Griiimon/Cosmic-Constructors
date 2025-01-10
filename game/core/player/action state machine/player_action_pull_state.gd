class_name PlayerPullState
extends PlayerActionStateMachineState

@export var min_strength: float= 1000.0
@export var max_strength: float= 10000.0

var pullable: PullableComponent



func on_enter():
	player.play_animation("steer")
	if not player.is_in_third_person():
		player.fps_arms.show()


func on_exit():
	player.reset_animation()
	player.fps_arms.hide()
	

func on_physics_process(delta: float):
	if Input.is_action_just_pressed("item_interact") or Input.is_action_just_pressed("pull"):
		finished.emit()

	var rb: RigidBody3D= pullable.get_rigidbody()
	var dist: float= rb.global_position.distance_to(player.global_position)
	dist= clampf(dist, pullable.min_radius, pullable.max_radius)
	var strength: float= remap(dist, pullable.min_radius, pullable.max_radius, min_strength, max_strength)
	strength*= delta
	rb.apply_central_force(rb.global_position.direction_to(player.global_position) * strength)


func on_enter_first_person():
	player.fps_arms.show()


func on_enter_third_person():
	player.fps_arms.hide()
