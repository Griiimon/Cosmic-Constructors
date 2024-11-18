class_name SuspensionInstance
extends BlockInstance

@export var wheel_scene: PackedScene

var can_steer:= BlockPropBool.new("Steering", true)

var wheel: Wheel



@export_group("Steering")
## The rate the steering input changes to smooth input.
## Steering input is between -1 and 1. Speed is in units per second.
@export var steering_speed := 4.25
## The rate the steering input changes when steering back to center.
## Speed is in units per second.
@export var countersteer_speed := 11.0
## Reduces steering input based on the cars velocity.
## Steering speed is divided by the velocity at this magnitude.
## The larger the number, the slower the steering at speed.
@export var steering_speed_decay := 0.20
## Further steering input is prevented if the wheels lateral slip is greater than this number.
@export var steering_slip_assist := 0.15
## The magnitude to adjust steering toward the direction of travel based on the cars lateral velocity.
@export var countersteer_assist := 0.9
## Steering input is raised to the power of this number.
## This has the effect of slowing steering input near the limits.
@export var steering_exponent := 1.5
## The maximum steering angle in radians.
@export var max_steering_angle := 0.7



@export_group("Throttle and Braking")
## The rate the throttle input changes to smooth input.
## Throttle input is between 0 and 1. Speed is in units per second.
@export var throttle_speed := 20.0
## Multiply the throttle speed by this based on steering input.
@export var throttle_steering_adjust := 0.1
## The rate braking input changes to smooth input.
## Braking input is between 0 and 1. Speed is in units per second.
@export var braking_speed := 10.0
## Multiplies the automatically calculated brake force.
@export var brake_force_multiplier := 1.0
## Prevents engine power from causing the tires to slip beyond this.
## Values below 0 disable the effect.
@export var traction_control_max_slip := 8.0


#@export_group("Motor")
### Maximum motor torque in NM.
#@export var max_torque := 300.0
### Maximum motor RPM.
#@export var max_rpm := 7000.0
### Idle motor RPM.
#@export var idle_rpm := 1000.0
### Percentage of torque produced across the RPM range.
#@export var torque_curve : Curve
### Variable motor drag based on RPM.
#@export var motor_drag := 0.005
### Constant motor drag.
#@export var motor_brake := 10.0
### Moment of inertia for the motor.
#@export var motor_moment := 0.5
### The motor will use this rpm when launching from a stop.
#@export var clutch_out_rpm := 3000.0
### Max clutch torque as a ratio of max motor torque.
#@export var max_clutch_torque_ratio := 1.6


#@export_group("Gearbox")
### Transmission gear ratios, the size of the array determines the number of gears
#@export var gear_ratios : Array[float] = [ 3.8, 2.3, 1.7, 1.3, 1.0, 0.8 ] 
### Final drive ratio
#@export var final_drive := 3.2
### Reverse gear ratio
#@export var reverse_ratio := 3.3
### Time it takes to change gears on up shifts in seconds
#@export var shift_time := 0.3
### Enables automatic gear changes
#@export var automatic_transmission := true
### Timer to prevent the automatic gear shifts changing gears too quickly 
### in milliseconds
#@export var automatic_time_between_shifts := 1000.0
### Drivetrain inertia
#@export var gear_inertia := 0.02


#@export_group("Tires")
### Represents the length of the tire contact patch in the brush tire model.
#@export var contact_patch := 0.2
### Provides additional longitudinal grip when braking.
#@export var braking_grip_multiplier := 1.5
### Tire force applied to the ground is also applied to the vehicle body as a
### torque centered on the wheel. 
#@export var wheel_to_body_torque_multiplier := 1.0
### Represents tire stiffness in the brush tire model. Higher values increase
### the responsivness of the tire.
### Surface detection uses node groups to identify the surface, so make sure
### your staticbodies and rigidbodies belong to one of these groups.
#@export var tire_stiffnesses := { "Road" : 10.0, "Dirt" : 0.5, "Grass" : 0.5 }
### A multiplier for the amount of force a tire can apply based on the surface.
### Surface detection uses node groups to identify the surface, so make sure
### your staticbodies and rigidbodies belong to one of these groups.
#@export var coefficient_of_friction := { "Road" : 3.0, "Dirt" : 2.4, "Grass" : 2.0 }
### A multiplier for the amount of rolling resistance force based on the surface.
### Surface detection uses node groups to identify the surface, so make sure
### your staticbodies and rigidbodies belong to one of these groups.
#@export var rolling_resistance := { "Road" : 1.0, "Dirt" : 2.0, "Grass" : 4.0 }
### A multiplier to provide more grip based on the amount of lateral wheel slip.
### This can be used to keep vehicles from sliding a long distance, but may provide
### unrealistically high amounts of grip.
### Surface detection uses node groups to identify the surface, so make sure
### your staticbodies and rigidbodies belong to one of these groups.
#@export var lateral_grip_assist := { "Road" : 0.05, "Dirt" : 0.0, "Grass" : 0.0}
### A multiplier to adjust longitudinal grip to differ from lateral grip.
### Useful for allowing vehicles to have wheel spin and maintain high lateral grip.
### Surface detection uses node groups to identify the surface, so make sure
### your staticbodies and rigidbodies belong to one of these groups.
#@export var longitudinal_grip_ratio := { "Road" : 0.5, "Dirt": 0.5, "Grass" : 0.5}


#@export_group("Aerodynamics")
### Coefficient of Drag
#@export var coefficient_of_drag := 0.3
### Air Density
#@export var air_density := 1.225
### Frontal area of the car in meters squared.
#@export var frontal_area := 2.0

const ANGULAR_VELOCITY_TO_RPM := 60.0 / TAU


## Controller Inputs: An external script should set these values
var throttle_input := 0.0
var steering_input := 0.0
var brake_input := 0.0
var handbrake_input := 0.0
var clutch_input := 0.0
################################################################

var is_ready := false
var local_velocity := Vector3.ZERO
var previous_global_position := Vector3.ZERO
var speed := 0.0
var motor_rpm := 0.0

var steering_amount := 0.0
var steering_exponent_amount := 0.0
var true_steering_amount := 0.0
var throttle_amount := 0.0
var brake_amount := 0.0
var torque_output := 0.0
var brake_force := 0.0
var handbrake_force := 0.0
var max_handbrake_force := 0.0
var is_braking := false


var delta_time := 0.0

var vehicle_inertia : Vector3



func _ready() -> void:
	default_interaction_property= can_steer


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	wheel= wheel_scene.instantiate()
	wheel.position= position + basis.x
	grid.add_child(wheel)
	wheel.initialize()


func on_destroy():
	wheel.queue_free()
	queue_free()


func on_update():
	if get_parent() != wheel.get_parent():
		wheel.reparent(get_parent())


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var forward_drive: float= round(max(0, -grid.requested_movement.z))
	var final_brake: float= round(max(0, grid.requested_movement.z))

	# no braking if we are driving
	if forward_drive > 0:
		final_brake = 0

	throttle_input= forward_drive
	brake_input= final_brake
	steering_input= -round(grid.requested_movement.x)

	# brake if movement opposite indended direction
	#if sign(grid.get_current_speed()) != sign(forward_drive) && !is_zero_approx(grid.linear_v) && forward_drive != 0:
	#final_brake = max_braking_coef * abs(forward_drive)
	#final_brake = abs(forward_drive)
		
	## no drive inputs, apply parking brake if sitting still
	#if forward_drive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
		#final_brake = max_braking_coef

	if wheel:
		#if wheel.is_at_travel_limit():
			#grid.add_effect(BlockGridCancelYVelocityEffect.new(pow(1 + wheel.max_travel - wheel.previous_distance, 8) - 1, wheel.previous_hit.hit_normal))
			#wheel.brake(1)
			#DebugHud.send("Over", "%.4f" % ( wheel.max_travel - wheel.previous_distance ))
	
		delta_time += delta
		local_velocity = lerp(((grid.global_transform.origin - previous_global_position) / delta) * global_transform.basis, local_velocity, 0.5)
		previous_global_position = grid.global_position
		speed = local_velocity.length()
		
		#process_drag()
		process_braking(grid, wheel, delta)
		if can_steer.is_true():
			process_steering(delta)
		process_throttle(delta)
		process_motor(delta)
		process_drive(delta)
		process_forces(grid, delta)


#func process_drag() -> void:
	#var drag := 0.5 * air_density * pow(speed, 2.0) * frontal_area * coefficient_of_drag
	#if drag > 0.0:
		#apply_central_force(-local_velocity.normalized() * drag)


func process_braking(grid: BlockGrid, wheel: Wheel, delta : float) -> void:
	if (brake_input < brake_amount):
		brake_amount -= braking_speed * delta
		if (brake_input > brake_amount):
			brake_amount = brake_input
	
	elif (brake_input > brake_amount):
		brake_amount += braking_speed * delta
		if (brake_input < brake_amount):
			brake_amount = brake_input
	
	if brake_amount > 0.0:
		is_braking = true
	else:
		is_braking = false
	
	#var friction := calculate_average_tire_friction(vehicle_mass * 9.8, "Road")
	var friction := calculate_average_tire_friction(grid.mass * grid.current_gravity.dot(-global_basis.y), "Road")
	#max_brake_force = ((friction * braking_grip_multiplier) * average_drive_wheel_radius) / wheel_array.size()
	var max_brake_force: float = ((friction * wheel.braking_grip_multiplier) * wheel.tire_radius)
	#max_handbrake_force = ((friction * braking_grip_multiplier * 0.05) / average_drive_wheel_radius)

	brake_force = brake_amount * max_brake_force
	DebugHud.send("Brake", brake_force)
	handbrake_force = handbrake_input * max_handbrake_force


func process_steering(delta : float) -> void:
	wheel.steer(steering_input, max_steering_angle)
	return

	var steer_assist_engaged := false
	var steering_slip := get_max_steering_slip_angle()
	
	## Adjust steering speed based on vehicle speed and max steering angle
	var steer_speed_correction := steering_speed / (speed * steering_speed_decay) / max_steering_angle
	
	## If the steering input is opposite the current steering, apply countersteering speed instead
	if signf(steering_input) != signf(steering_amount):
		steer_speed_correction = countersteer_speed / (speed * steering_speed_decay)
	
	## Check steering slip threshold and reduce steering amount if crossed.
	if absf(steering_slip) > steering_slip_assist:
		steer_assist_engaged = true
	
	if (steering_input < steering_amount):
		if not steer_assist_engaged or steering_slip < 0.0:
			steering_amount -= steer_speed_correction * delta
			if (steering_input > steering_amount):
				steering_amount = steering_input
		else:
			steering_amount += steer_speed_correction * delta
			if (steering_amount > 0.0):
				steering_amount = 0.0
	
	elif (steering_input > steering_amount):
		if not steer_assist_engaged or steering_slip > 0.0:
			steering_amount += steer_speed_correction * delta
			if (steering_input < steering_amount):
				steering_amount = steering_input
		else:
			steering_amount -= steer_speed_correction * delta
			if (steering_amount < 0.0):
				steering_amount = 0.0
	
	## Steering exponent adjustment
	var steering_adjust := pow(absf(steering_amount), steering_exponent) * signf(steering_amount)
	
	### Correct steering toward the direction of travel for countersteer assist
	#var steer_correction := (1.0 - absf(steering_adjust)) * clampf(asin(local_velocity.normalized().x), -max_steering_angle, max_steering_angle) * countersteer_assist
	
	### Don't apply corrections at low velocity or reversing
	#if local_velocity.z > -0.5:
		#steer_correction = 0
	#else:
		#steer_correction = steer_correction / -max_steering_angle
	#
	### Keeps steering corrections from getting stuck under certain circumstances
	#var steer_correction_amount := 1.0
	#if signf(steering_adjust + steer_correction) != signf(steering_input) and 1.0 - absf(steering_input) < steer_correction_amount:
		#steer_correction_amount = clampf(steer_correction_amount - (steering_speed * delta), 0.0, 1.0)
	#else:
		#steer_correction_amount = clampf(steer_correction_amount + (steering_speed * delta), 0.0, 1.0)
	#
	#steer_correction *= steer_correction_amount
	
	var steer_correction:= 0.0
	
	true_steering_amount = clampf(steering_adjust + steer_correction, -max_steering_angle, max_steering_angle)
	
	#for wheel in wheel_array:
	wheel.steer(steering_adjust + steer_correction, max_steering_angle)


func process_throttle(delta : float) -> void:
	var throttle_delta := throttle_speed * delta
	
	if (throttle_input < throttle_amount):
		throttle_amount -= throttle_delta
		if (throttle_input > throttle_amount):
			throttle_amount = throttle_input
	
	elif (throttle_input >= throttle_amount):
		throttle_amount += throttle_delta
		if (throttle_input < throttle_amount):
			throttle_amount = throttle_input


func process_motor(delta : float) -> void:
	#var drag_torque := motor_rpm * motor_drag
	#torque_output = get_torque_at_rpm(motor_rpm) * throttle_amount
	### Adjust torque based on throttle input, clutch input, and motor drag
	#torque_output -= drag_torque * (1.0 + (clutch_amount * (1.0 - throttle_amount)))
	#
	### Prevent motor from outputing torque below idle or far beyond redline
	#var new_rpm := motor_rpm
	#new_rpm += ANGULAR_VELOCITY_TO_RPM * delta * torque_output / motor_moment
	#motor_is_redline = false
	#if new_rpm > max_rpm * 1.1 or new_rpm <= idle_rpm:
		#torque_output = 0.0
		#if new_rpm > max_rpm * 1.1:
			#motor_is_redline = true
	#
	#motor_rpm += ANGULAR_VELOCITY_TO_RPM * delta * (torque_output - drag_torque) / motor_moment
	#
	### Disengage clutch when near idle
	#if motor_rpm < idle_rpm + 100:
		#need_clutch = true
	#elif new_rpm > clutch_out_rpm:
		#need_clutch = false
	#
	#motor_rpm = maxf(motor_rpm, idle_rpm)
	motor_rpm= throttle_amount * 1000


func process_drive(delta : float) -> void:
	process_axle_drive(motor_rpm, 0, delta)


func process_axle_drive(torque : float, drive_inertia : float, delta : float) -> void:
	wheel.process_torque(torque, drive_inertia, brake_force, false, delta)


func process_forces(grid: BlockGrid, delta : float) -> void:
	wheel.process_forces(grid, 0, is_braking, delta)


func get_max_steering_slip_angle() -> float:
	var steering_slip := 0.0
	if absf(steering_slip) < absf(wheel.slip_vector.x):
		steering_slip = wheel.slip_vector.x
	return steering_slip


func calculate_average_tire_friction(weight : float, surface : String) -> float:
	#var friction := 0.0
	#for wheel in wheel_array:
		#friction += wheel.get_friction(weight / wheel_array.size(), surface)
	#return friction
	# TODO divide by number of wheels having ground contact ( previous tick )
	return wheel.get_friction(weight)


#func calculate_brake_force(grid: BlockGrid) -> void:
	##var friction := calculate_average_tire_friction(vehicle_mass * 9.8, "Road")
	#var friction := calculate_average_tire_friction(grid.mass * grid.current_gravity.dot(-global_basis.y), "Road")
	##max_brake_force = ((friction * braking_grip_multiplier) * average_drive_wheel_radius) / wheel_array.size()
	#max_brake_force = ((friction * wheel.braking_grip_multiplier) * wheel.tire_radius)
	##max_handbrake_force = ((friction * braking_grip_multiplier * 0.05) / average_drive_wheel_radius)
