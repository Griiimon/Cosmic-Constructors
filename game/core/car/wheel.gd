# adapted from https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics/blob/main/addons/gevp/scripts/wheel.gd

# Portions are Copyright (c) 2021 Dechode
# https://github.com/Dechode/Godot-Advanced-Vehicle

# Portions are Copyright (c) 2024 Baron Wittman
# https://lupine-vidya.itch.io/gdsim/devlog/677572/series-driving-simulator-workshop-mirror

class_name Wheel
extends RigidBody3D

@onready var model: Node3D = $Model


@export var wheel_mass := 1.0
@export var tire_radius := 3.0
@export var tire_width := 205.0
@export var ackermann := 0.15
@export var contact_patch := 0.2
@export var braking_grip_multiplier := 0.01

var surface_type := "Road"
var tire_stiffnesses := { "Road" : 5.0, "Dirt" : 0.5, "Grass" : 0.5 }
var coefficient_of_friction := { "Road" : 2.0, "Dirt" : 1.4, "Grass" : 1.0 }
var rolling_resistance := { "Road" : 1.0, "Dirt" : 2.0, "Grass" : 4.0 }
var lateral_grip_assist := { "Road" : 0.05, "Dirt" : 0.0, "Grass" : 0.0}
var longitudinal_grip_ratio := { "Road" : 0.5, "Dirt": 0.5, "Grass" : 0.5}

#@export var spring_length := 1
#@export var spring_rate := 5
#@export var slow_bump := 0.1
#@export var fast_bump := 1.0
#@export var slow_rebound := 0.1
#@export var fast_rebound := 1.0
#@export var fast_damp_threshold := 12700.0
#@export var antiroll := 0.0
#@export var toe := 0.0
#@export var bump_stop_multiplier := 1.0
@export var wheel_to_body_torque_multiplier := 0.0
@export var mass_over_wheel := 1.0

var suspension: SuspensionInstance

var spring_length: float
var spring_rate: float

var wheel_moment := 0.0
var spin := 0.0
var spin_velocity_diff := 0.0
var spring_force := 0.0
var applied_torque := 0.0
var local_velocity := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var previous_global_position := Vector3.ZERO
var force_vector := Vector2.ZERO
var slip_vector := Vector2.ZERO
var previous_compression := 0.0
var spring_current_length := 0.0
var max_spring_length := 0.0
var damping_force := 0.0

var last_collider
var last_collision_point := Vector3.ZERO
var last_collision_normal := Vector3.ZERO
var current_cof := 0.0
var current_rolling_resistance := 0.0
var current_lateral_grip_assist := 0.0
var current_longitudinal_grip_ratio := 0.0
var current_tire_stiffness := 0.0

var abs_enable_time := 0.0
var abs_pulse_time := 0.3
var abs_spin_difference_threshold := -12.0
var limit_spin := false

var grounded:= false
var bottom_out := false



func _ready() -> void:
	previous_global_position= global_position


func _process(delta : float) -> void:
	model.rotation.x -= (wrapf(spin * delta, 0, TAU))


func initialize(grid: BlockGrid, _suspension: SuspensionInstance) -> void:
	suspension= _suspension
	spring_length= suspension.spring_length
	spring_rate= suspension.get_spring_rate()
	
	model.rotation_order = EULER_ORDER_ZXY
	wheel_moment = 0.5 * wheel_mass * pow(tire_radius, 2)

	max_spring_length = spring_length
	current_cof = coefficient_of_friction[surface_type]
	current_rolling_resistance = rolling_resistance[surface_type]
	current_lateral_grip_assist = lateral_grip_assist[surface_type]
	current_longitudinal_grip_ratio = longitudinal_grip_ratio[surface_type]
	current_tire_stiffness = 1000000.0 + 8000000.0 * tire_stiffnesses[surface_type]


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		grounded= true
		last_collider= state.get_contact_collider_object(0)
		last_collision_point= state.get_contact_collider_position(0)
		last_collision_normal= state.get_contact_local_normal(0)
	else:
		grounded= false
		last_collider= null


# TODO what in here currently has any impact?
func process_torque(drive : float, drive_inertia : float, brake_torque : float, brake_abs : bool, delta : float) -> float:
	#DebugHud.send("Drive" + name.right(3), drive)
	## Add the torque the wheel produced last frame from surface friction
	var net_torque := force_vector.y * tire_radius
	var previous_spin := spin
	net_torque += drive
	
	## If antilock brakes are still active, don't apply brake torque
	#if abs_enable_time > vehicle.delta_time:
	if abs_enable_time > delta:
		brake_torque = 0.0
		brake_abs = false
	
	## If the wheel slip from braking is too great, enable the antilock brakes
	if absf(spin) > 5.0 and spin_velocity_diff < abs_spin_difference_threshold:
		if brake_abs and brake_torque > 0.0:
			brake_torque = 0.0
			#abs_enable_time = vehicle.delta_time + abs_pulse_time
			abs_enable_time = delta + abs_pulse_time
	
	## Applied torque is used to ensure the wheels don't apply more force
	## than the motor or brakes applied to the wheel
	if is_zero_approx(spin):
		applied_torque = absf(drive - brake_torque)
	else:
		applied_torque = absf(drive - (brake_torque * signf(spin)))
	
	## If braking and nearly stopped, just stop the wheel completely.
	if absf(spin) < 5.0 and brake_torque > absf(net_torque):
		if brake_abs and absf(local_velocity.z) > 2.0:
			#abs_enable_time = vehicle.delta_time + abs_pulse_time
			abs_enable_time = delta + abs_pulse_time
		else:
			spin = 0.0
	else:
		## Spin the wheel based on the provided torque. The tire forces will handle
		## applying that force to the vehicle.
		net_torque -= brake_torque * signf(spin)
		var new_spin : float = spin + ((net_torque / (wheel_moment + drive_inertia)) * delta)
		if signf(spin) != signf(new_spin) and brake_torque > absf(drive):
			new_spin = 0.0
		spin = new_spin
	
	#spin= spin * (-1 if ( reverse and not is_zero_approx(drive) ) else 1)
	
	#DebugHud.send("Spin", spin)
	
	## The returned value is used to track wheel speed difference
	if is_zero_approx(drive * delta):
		return 0.5
	else:
		return (spin - previous_spin) * (wheel_moment + drive_inertia) / (drive * delta)


func process_forces(grid: BlockGrid, braking : bool, delta : float) -> float:
	previous_velocity = local_velocity
	local_velocity = (global_position - previous_global_position) / delta * global_transform.basis
	previous_global_position = global_position
	
	# TODO implement surface types
	#if grounded:
			#var surface_groups : Array[StringName] = last_collider.get_groups()
			#if surface_groups.size() > 0:
				#if surface_type != surface_groups[0]:
					#surface_type = surface_groups[0]
					#current_cof = coefficient_of_friction[surface_type]
					#current_rolling_resistance = rolling_resistance[surface_type]
					#current_lateral_grip_assist = lateral_grip_assist[surface_type]
					#current_longitudinal_grip_ratio = longitudinal_grip_ratio[surface_type]
					#current_tire_stiffness = 1000000.0 + 8000000.0 * tire_stiffnesses[surface_type]
	
	var compression := process_suspension(grid, delta)
	
	if grounded and last_collider:
		process_tires(braking, delta)
		var contact := last_collision_point - grid.global_position

		#DebugHud.send("Spring" + name.right(3), spring_force)
		#DebugHud.send("Spring length" + name.right(3), spring_current_length)
		DebugHud.send("FVec" + name.right(3), Utils.get_short_vec2(force_vector))
		
		grid.apply_force(global_transform.basis.x * force_vector.x, contact)
		grid.apply_force(global_transform.basis.z * force_vector.y, contact)
		
		## Applies a torque on the vehicle body centered on the wheel. Gives the vehicle 
		## more weight transfer when the center of gravity is really low.
		if braking:
			wheel_to_body_torque_multiplier = 1.0 / (braking_grip_multiplier + 1.0)
		grid.apply_force(-global_transform.basis.y * force_vector.y * 0.5 * wheel_to_body_torque_multiplier, to_global(Vector3.FORWARD * tire_radius))
		grid.apply_force(global_transform.basis.y * force_vector.y * 0.5 * wheel_to_body_torque_multiplier, to_global(Vector3.BACK * tire_radius))
		
		return compression
	
	else:
		force_vector = Vector2.ZERO
		slip_vector = Vector2.ZERO
		spin -= signf(spin) * delta * 2.0 / wheel_moment
		return 0.0


func process_suspension(grid: BlockGrid, delta : float) -> float:
	if grounded and last_collider:
		#spring_current_length = last_collision_point.distance_to(query.transform.origin) - tire_radius
		spring_current_length = -suspension.to_local(global_position).y + spring_length / 2.0
	else:
		spring_current_length = spring_length
	

	var no_contact := false
	if spring_current_length > max_spring_length:
		spring_current_length = max_spring_length
		no_contact = true

	
	var compression := (spring_length - spring_current_length) * 1000.0
	
	var spring_speed_mm_per_seconds := (compression - previous_compression) / delta
	previous_compression = compression
	
	spring_force = compression * spring_rate
	
	

	if no_contact:
		spring_force = 0.0
	
	return compression


func process_tires(braking : bool, delta : float):
	## This is a modified version of the brush tire model that removes the friction falloff beyond
	## the peak grip level.
	var local_planar := Vector2(local_velocity.x, local_velocity.z).normalized() * clampf(local_velocity.length(), 0.0, 1.0)
	slip_vector.x = asin(clampf(-local_planar.x, -1.0, 1.0))
	slip_vector.y = 0.0
	
	var wheel_velocity := spin * tire_radius
	spin_velocity_diff = wheel_velocity + local_velocity.z
	var needed_rolling_force := ((spin_velocity_diff * wheel_moment) / tire_radius) / delta
	var max_y_force := 0.0
	
	## Because the amount of force the tire applies is based on the amount of slip,
	## a maximum force is calculated based on the applied engine torque to prevent
	## the tire from creating too much force.
	if absf(applied_torque) > absf(needed_rolling_force):
		max_y_force = absf(applied_torque / tire_radius)
	else:
		max_y_force = absf(needed_rolling_force / tire_radius)
	
	var max_x_force := 0.0
	max_x_force = absf(mass_over_wheel * local_velocity.x) / delta
	
	var z_sign := signf(-local_velocity.z)
	if local_velocity.z == 0.0:
		z_sign = 1.0
	
	slip_vector.y = ((absf(local_velocity.z) - (wheel_velocity * z_sign)) / (1.0 + absf(local_velocity.z)))
	
	if slip_vector.is_zero_approx():
		slip_vector = Vector2(0.0001, 0.0001)
	
	var cornering_stiffness := 0.5 * current_tire_stiffness * pow(contact_patch, 2.0)
	var friction := current_cof * spring_force - (spring_force / (tire_width * contact_patch * 0.2))
	var deflect := 1.0 / (sqrt(pow(cornering_stiffness * slip_vector.y, 2.0) + pow(cornering_stiffness * slip_vector.x, 2.0)))


	## Adds in additional longitudinal grip when braking
	var braking_help := 1.0
	if slip_vector.y > 0.3 and braking:
		braking_help = (1 + (braking_grip_multiplier * clampf(absf(slip_vector.y), 0.0, 1.0)))
	
	var crit_length := friction * (1.0 - slip_vector.y) * contact_patch * (0.5 * deflect)
	if crit_length >= contact_patch:
		force_vector.y = cornering_stiffness * slip_vector.y / (1.0 - slip_vector.y)
		force_vector.x = cornering_stiffness * slip_vector.x / (1.0 - slip_vector.y)
	else:
		var brushx := (1.0 - friction * (1.0 - slip_vector.y) * (0.25 * deflect)) * deflect

		force_vector.y = friction * current_longitudinal_grip_ratio * cornering_stiffness * slip_vector.y * brushx * braking_help * z_sign
		force_vector.x = friction * cornering_stiffness * slip_vector.x * brushx * (absf(slip_vector.x * current_lateral_grip_assist) + 1.0)


	if absf(force_vector.y) > absf(max_y_force):
		force_vector.y = max_y_force * signf(force_vector.y)
		limit_spin = true
	else:
		limit_spin = false
	
	if absf(force_vector.x) > max_x_force:
		force_vector.x = max_x_force * signf(force_vector.x)

	# There always seems to be a counterforce applied that evens out the rolling resistance
	# ( during the next frame? )

	#var resistance_force: float= process_rolling_resistance() * signf(local_velocity.z) 
	#force_vector.y -= resistance_force


func process_rolling_resistance() -> float:
	var rolling_resistance_coefficient := 0.005 + (0.5 * (0.01 + (0.0095 * pow(local_velocity.z * 0.036, 2))))
	return rolling_resistance_coefficient * spring_force * current_rolling_resistance


func get_reaction_torque() -> float:
	return force_vector.y * tire_radius


func get_friction(normal_force : float, surface : String= "Road") -> float:
	var surface_cof := 1.0
	if coefficient_of_friction.has(surface):
		surface_cof = coefficient_of_friction[surface]
	return surface_cof * normal_force - (normal_force / (tire_width * contact_patch * 0.2))
