class_name PlayerMovementStateMachineState
extends PlayerStateMachineState

signal jetpack_enabled
signal left_ground

@export var turn_factor: float= 1.0
@export var pitch_factor: float= 1.0

@export var walk_speed: float= 4.0
@export var strafe_speed: float= 4.0
@export var run_factor: float= 3.0
@export var move_back_factor: float= 0.5



func on_enter():
	player.freeze= true
	player.collision_shape.disabled= true
	await get_tree().physics_frame
	
	#player.global_transform= Utils.align_with_y(player.global_transform, get_floor_normal())


func on_exit():
	player.collision_shape.disabled= false
	player.freeze= false
	

func on_physics_process(delta: float):
	if not player.floor_shapecast.is_colliding():
		left_ground.emit()
		return
		
	if Input.is_action_just_pressed("jetpack"):
		#player.position.y+= 0.1
		jetpack_enabled.emit()
		return

	var floor_normal: Vector3= get_floor_normal()
	if floor_normal.is_zero_approx(): return
	
	player.global_transform= player.global_transform.interpolate_with(Utils.align_with_y(player.global_transform, floor_normal), delta * 10)
	
	var current_run_factor: float= 1.0
	if Input.is_action_pressed("run"):
		current_run_factor= run_factor

	var move_vec: float= Input.get_action_strength("move_forward") * current_run_factor - Input.get_action_strength("move_back") * move_back_factor
	move_vec*= walk_speed
	var strafe_vec: float= Input.get_axis("strafe_left", "strafe_right")
	strafe_vec*= strafe_speed

	var final_move: Vector3
	final_move= -player.head.global_basis.z * move_vec * delta
	final_move+= player.head.global_basis.x * strafe_vec * delta

	var plane:= Plane(floor_normal)
	player.global_position+= plane.project(final_move)


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		player.head.rotate_y(deg_to_rad(-event.relative.x) * turn_factor)
		#player.pivot.rotate_x(deg_to_rad(-event.relative.y) * pitch_factor)
		player.pivot.rotate_x(deg_to_rad(-event.relative.y) * pitch_factor)
		#player.pivot.rotation.x= clamp(player.pivot.rotation.x, -deg_to_rad(45), deg_to_rad(45))


func get_floor_normal()-> Vector3:
	var result:= Vector3.ZERO
	for idx in player.floor_shapecast.get_collision_count():
		result+= player.floor_shapecast.get_collision_normal(idx)
	return result.normalized()
