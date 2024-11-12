class_name Wheel
extends Node3D

@export_category("Suspension")
@export_flags_3d_physics var mask : int = 1
@export var cast_to : Vector3 = Vector3(0,-3,0)

@export var spring_max_force : float = 3000.0
@export var spring_force : float = 1800.0
@export var stiffness : float = 0.85
@export var damping : float = 0.05
@export var x_traction : float = 0.1
@export var z_traction : float = 0.15
@export var static_slide_threshold : float = 0.005
@export var mass_kg : float = 100.0

@export var max_steer_angle: float= 30
@export var steering_speed: float= 50

@export var acceleration: float= 10.0

@onready var parent_body : BlockGrid = get_parent()
@onready var previous_distance : float = abs(cast_to.y)

var instant_linear_velocity : Vector3
var previous_hit : HitResult = HitResult.new()
var collision_point : Vector3 = cast_to
var grounded : bool = false

var steer_input: float= 0.0
var forward_drive: float= 0.0


class HitResult:
	var hit_distance : float
	var hit_position : Vector3
	var hit_normal : Vector3
	var hit_point_velocity : Vector3
	var hit_body : PhysicsBody3D



# function to do sphere casting
func shape_cast(origin: Vector3, offset: Vector3):
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	var query:= PhysicsRayQueryParameters3D.create(origin, origin + offset, mask)
	var cast_result= space.intersect_ray(query)

	var result : HitResult = HitResult.new()
	
	result.hit_distance = origin.distance_to(cast_result.position) if cast_result else cast_to.length()
	result.hit_position = cast_result.position if cast_result else origin + offset
	
	result.hit_normal = cast_result.normal if cast_result else Vector3.ZERO
	result.hit_point_velocity = Vector3.ZERO
	result.hit_body = null
	
	# if a valid object has been hit
	#if result:
		# get the reference to the actual PhysicsBody that we are in contact with
		#result.hit_body = instance_from_id(PhysicsServer3D.body_get_object_instance_id(collision.get("rid")))
		# get the velocity of the hit body at point of contact
		#var hitBodyState := PhysicsServer3D.body_get_direct_state(collision.get("rid"))
		#var hitBodyPoint : Vector3 = collision.get("point")
		
		#result.hit_point_velocity = hitBodyState.get_velocity_at_local_position(hitBodyState.transform.xform_inv(hitBodyPoint))
		# TODO check if translated correctly
		#result.hit_point_velocity = hitBodyState.get_velocity_at_local_position(hitBodyPoint * hitBodyState.transform)
		#if GameState.debugMode:
			#DrawLine3D.DrawRay(result.hit_position,result.hit_point_velocity,Color(0,0,0))
	
	return result


# set forward friction (braking)
func apply_brake(amount : float = 0.0) -> void:
	z_traction = max(0.0, amount)


# function for applying drive force to parent body (if grounded)
func apply_force(force : Vector3) -> void:
	if grounded:
		parent_body.add_force(force, collision_point - parent_body.global_transform.origin)


func _physics_process(delta) -> void:
	# perform sphere cast
	var cast_result = shape_cast(global_transform.origin, cast_to)
	collision_point = cast_result.hit_position
	#if GameState.debugMode:
		#DrawLine3D.DrawCube(global_transform.origin,0.1,Color(255,0,255))
		#DrawLine3D.DrawCube(global_transform.origin + cast_to,0.1,Color(255,128,255))
	# [1, 1] means no hit (from docs)
	#if cast_result.hit_distance != abs(cast_to.y):
	if not is_equal_approx(cast_result.hit_distance, abs(cast_to.y)):
		# if grounded, handle forces
		grounded = true
#		collision_point = cast_result.hit_position
		#if GameState.debugMode:
			#DrawLine3D.DrawCube(cast_result.hit_position,0.04,Color(0,255,255))
			#DrawLine3D.DrawRay(cast_result.hit_position,cast_result.hit_normal,Color(255,255,255))
		
		# obtain instantaneaous linear velocity
		instant_linear_velocity = (collision_point - previous_hit.hit_position) / delta
		
		# apply spring force with damping force
		var current_distance : float = cast_result.hit_distance
		var f_spring : float = stiffness * (abs(cast_to.y) - current_distance) 
		var f_damp : float = damping * (previous_distance - current_distance) / delta
		var suspension_force : float = clamp((f_spring + f_damp) * spring_force,0,spring_max_force)
		var suspension_force_vec : Vector3 = cast_result.hit_normal * suspension_force
		
		# obtain axis velocity
		#var local_velocity : Vector3 = global_transform.basis.xform_inv(instant_linear_velocity - cast_result.hit_point_velocity) 
		# TODO check if translated correctly
		var local_velocity : Vector3 = (instant_linear_velocity - cast_result.hit_point_velocity) * global_transform.basis
		
		# axis deceleration forces based on this drive elements mass and current acceleration
		var x_accel : float = (-local_velocity.x * x_traction) / delta
		var z_accel : float = (-local_velocity.z * z_traction) / delta
		var x_force : Vector3 = global_transform.basis.x * x_accel * mass_kg
		var z_force : Vector3 = global_transform.basis.z * z_accel * mass_kg
		
		# counter sliding by negating off axis suspension impulse at very low speed
		var v_limit : float = instant_linear_velocity.length_squared() * delta
		if v_limit < static_slide_threshold:
#			suspension_force_vec = Vector3.UP * suspension_force
			x_force.x -= suspension_force_vec.x * parent_body.global_transform.basis.y.dot(Vector3.UP)
			z_force.z -= suspension_force_vec.z * parent_body.global_transform.basis.y.dot(Vector3.UP)
		
		# final impulse force vector to be applied
		var final_force = suspension_force_vec + x_force# + z_force
		
		# draw debug lines
		#if GameState.debugMode:
			#DrawLine3D.DrawRay(get_collision_point(),suspension_force_vec/GameState.debugRayScaleFac,Color(0,255,0))
			#DrawLine3D.DrawRay(get_collision_point(),x_force/GameState.debugRayScaleFac,Color(255,0,0))
			#DrawLine3D.DrawRay(get_collision_point(),z_force/GameState.debugRayScaleFac,Color(0,0,255))
			
		# apply forces relative to parent body
		DebugHud.send("Suspension force", final_force)
		parent_body.apply_force(final_force, collision_point - parent_body.global_transform.origin)
		
		# apply forces to body affected by this drive element (action = reaction)
		if cast_result.hit_body && cast_result.hit_body is RigidBody3D:
			cast_result.hit_body.apply_force(-final_force, collision_point - cast_result.hit_body.global_transform.origin)
		
		# set the previous values at the very end, after they have been used
		previous_distance = current_distance
		previous_hit = cast_result

		# apply drive force and braking
		parent_body.apply_force(-global_basis.z * forward_drive * acceleration, global_position - parent_body.global_position)

	else:
		# not grounded, set prev values to fully extended suspension
		grounded = false
		previous_hit = HitResult.new()
		previous_hit.hit_position = global_transform.origin + cast_to
		previous_hit.hit_distance = abs(cast_to.y)
		previous_distance = previous_hit.hit_distance
		instant_linear_velocity = Vector3.ZERO

	#DebugHud.send("Grounded", grounded)

	if steer_input:
		rotation.y= move_toward(rotation.y, sign(steer_input) * deg_to_rad(max_steer_angle), deg_to_rad(steering_speed) * delta)
	else:
		rotation.y= move_toward(rotation.y, 0.0, deg_to_rad(steering_speed) * delta)


func steer(input: float):
	steer_input= -input
