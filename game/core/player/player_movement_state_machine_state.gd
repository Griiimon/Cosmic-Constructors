class_name PlayerMovementStateMachineState
extends PlayerStateMachineState

signal jetpack_enabled(velocity: Vector3)
signal left_ground(velocity: Vector3)

@export var turn_factor: float= 1.0
@export var pitch_factor: float= 1.0

@export var walk_speed: float= 4.0
@export var strafe_speed: float= 4.0
@export var run_factor: float= 3.0
@export var move_back_factor: float= 0.5

@export var snap_factor: float= 5.0

@export var min_safe_snap_fraction: float= 0.65
@export var max_safe_snap_fraction: float= 0.75

var velocity: Vector3



func on_enter():
	player.freeze= true
	initial_align()


func on_exit():
	player.freeze= false
	

func on_physics_process(delta: float):
	if not player.floor_shapecast.is_colliding():
		left_ground.emit(velocity)
		return
		
	if Input.is_action_just_pressed("jetpack"):
		jetpack_enabled.emit(velocity)
		return

	var floor_normal: Vector3= get_floor_normal()
	if floor_normal.is_zero_approx(): return
	
	continuous_align(delta)
	
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

	var prev_position: Vector3= player.global_position
	
	pre_move()
	move_and_slide_and_snap(final_move, floor_normal, delta)
	post_move()

	velocity= (player.global_position - prev_position) / delta
	DebugHud.send("Velocity", "%.2f" % velocity.length())


func move_and_slide_and_snap(motion: Vector3, floor_normal: Vector3, delta: float, max_slides: int= 1):
	var safe_fraction: float= player.floor_shapecast.get_closest_collision_safe_fraction()
	#DebugHud.send("Safe Fraction", safe_fraction)

	# TODO or towards collision point, not target_position?
	var down_vec: Vector3= (player.to_global(player.floor_shapecast.target_position) - player.global_position).normalized()
	if safe_fraction > max_safe_snap_fraction:
		player.global_position+= down_vec * delta * snap_factor
	elif safe_fraction < min_safe_snap_fraction:
		player.global_position-= down_vec * delta * snap_factor
		

	if not motion:
		return
		
	for i in max_slides + 1:
		var collision: KinematicCollision3D= move_and_collide(motion)
		if not collision:
			player.global_position+= motion
			return

		var orig_pos: Vector3= player.floor_shapecast.position
		player.floor_shapecast.global_position= player.global_position + collision.get_travel()
		player.floor_shapecast.force_shapecast_update()
		player.floor_shapecast.position= orig_pos
		
		if player.floor_shapecast.is_colliding():
			if get_floor_normal().dot(floor_normal) < 0.5:
				return

		player.global_position+= collision.get_travel()
		motion= collision.get_remainder()
		motion= motion.slide(collision.get_normal(0))

	#var plane:= Plane(floor_normal)
	#final_move= plane.project(final_move)


func move_and_collide(motion: Vector3)-> KinematicCollision3D:
	var result: KinematicCollision3D
	return player.move_and_collide(motion, true)
	return result


func pre_move():
	pass


func post_move():
	pass


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		player.head.rotate_y(deg_to_rad(-event.relative.x) * turn_factor)
		player.pivot.rotate_x(deg_to_rad(-event.relative.y) * pitch_factor)


func initial_align():
	pass


func continuous_align(delta: float):
	pass


# FIXME floor shapecast always returns max 1 collision, so this isnt necessary?
func get_floor_normal()-> Vector3:
	var result:= Vector3.ZERO
	for idx in player.floor_shapecast.get_collision_count():
		result+= player.floor_shapecast.get_collision_normal(idx)
	return result.normalized()
