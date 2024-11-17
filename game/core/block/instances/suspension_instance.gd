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

@export_subgroup("Front Axle", "front_")
## How long the ABS releases the brake when the spin threshold is crossed.
@export var front_abs_pulse_time := 0.03
## The difference in speed between the wheel and the surface to engage ABS.
@export var front_abs_spin_difference_threshold := 12.0

@export_subgroup("Rear Axle", "rear_")
## How long the ABS releases the brake when the spin threshold is crossed.
@export var rear_abs_pulse_time := 0.03
## The difference in speed between the wheel and the surface to engage ABS.
@export var rear_abs_spin_difference_threshold := 12.0

#@export_group("Stability")
### Stablity applies torque forces to the vehicle body when the body angle
### relative to the direction of travel exceeds a threshold.
#@export var enable_stability := true
### The yaw angle the vehicle must reach before stability is applied.
### Based on the dot product, 0 being straight, 1 being 90 degrees
#@export var stability_yaw_engage_angle := 0.0
### Strength multiplier for the applied yaw correction.
#@export var stability_yaw_strength := 6.0
### Additional strength multiplier for a grounded vehicle to overcome traction.
#@export var stability_yaw_ground_multiplier := 2.0
### A multiplier for the torque used to keep the vehicle upright while airbourn.
#@export var stability_upright_spring := 1.0
### A multiplier for the torque used to dampen rotation while airborne.
#@export var stability_upright_damping := 1000.0


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


#@export_group("Drivetrain")
### Torque delivered to the front wheels vs the rear wheels.
### Value of 1 is FWD, a value of 0 is RWD, anything in between is AWD.
#@export var front_torque_split := 0.0
### When enabled, the torque split will change based on wheel slip.
#@export var variable_torque_split := false
### Torque split to interpolate toward when there is wheel slip. Variable Torque
### Split must be enabled.
#@export var front_variable_split := 0.0
### How quickly to interpolate between torque splits in seconds.
#@export var variable_split_speed := 1.0
#@export_subgroup("Front Axle", "front_")
### The wheels of the axle will be forced to spin the same speed if there
### is at least this much torque applied. Keeps vehicle from spinning one wheel.
### Torque is measured after multiplied by the current gear ratio.
### Negative values will disable.
#@export var front_locking_differential_engage_torque := 200.0
### The amount of torque vectoring to apply to the axle based on steering input.
### Only functions if the differential is locked.
### A value of 1.0 would apply all torque to the outside wheel.
#@export var front_torque_vectoring := 0.0
#@export_subgroup("Rear Axle", "rear_")
### The wheels of the axle will be forced to spin the same speed if there
### is at least this much torque applied. Keeps vehicle from spinning one wheel.
### Torque is measured after multiplied by the current gear ratio.
### Negative values will disable.
#@export var rear_locking_differential_engage_torque := 200.0
### The amount of torque vectoring to apply to the axle based on steering input.
### Only functions if the differential is locked.
### A value of 1.0 would apply all torque to the outside wheel.
#@export var rear_torque_vectoring := 0.0


@export_group("Suspension")
## Vehicle mass in kilograms.
#@export var vehicle_mass := 1500.0
## The percentage of the vehicle mass over the front axle.
#@export var front_weight_distribution := 0.5
### The center of gravity is calculated from the front weight distribution
### with the height centered on the wheel raycast positions. This will offset
### the height from that calculated position.
#@export var center_of_gravity_height_offset := -0.2
### Multiplies the calculated inertia by this value.
### Greater inertia values will cause more force to be
### required to rotate the car.
@export var inertia_multiplier := 1.2

@export_subgroup("Front Axle", "front_")
## The amount of suspension travel in meters.
@export var front_spring_length := 0.15
## How much the spring is compressed when the vehicle is at rest.
## This is used to calculate the approriate spring rate for the wheel.
## A value of 0 would be a fully compressed spring.
@export var front_resting_ratio := 0.5
## Damping ratio is used to calculate the damping forces on the spring.
## A value of 1 would be critically damped. Passenger cars typically have a
## ratio around 0.3, while a race car could be as high as 0.9.
@export var front_damping_ratio := 0.4
## Bump damping multiplier applied to the damping force calulated from the
## damping ratio. A typical ratio for a passenger car is 2/3 bump damping to
## 3/2 rebound damping. Race cars typically run 3/2 bump to 2/3 rebound.
@export var front_bump_damp_multiplier := 0.6667
## Rebound damping multiplier applied to the damping force calulated from the
## damping ratio. A typical ratio for a passenger car is 2/3 bump damping to
## 3/2 rebound damping. Race cars typically run 3/2 bump to 2/3 rebound.
@export var front_rebound_damp_multiplier := 1.5
## Antiroll bar stiffness as a ratio to spring stiffness.
@export var front_arb_ratio := 0.25
## Wheel camber isn't simulated, but giving the raycast a slight angle helps
## with simulation stability. Measured in radians.
@export var front_camber := 0.01745329
## Toe of the tires measured in radians.
@export var front_toe := 0.01
## Multiplier for the force applied when the suspension is fully compressed.
## If the vehicle bounces off large bumps, reducing this will help.
@export var front_bump_stop_multiplier := 1.0
## If true the wheels of this axle will be aligned as if they were attached to
## a beam axle. This setting does not affect vehicle handling.
@export var front_beam_axle := false

@export_subgroup("Rear Axle", "rear_")
## The amount of suspension travel in meters. Rear suspension typically has
## more travel than the front.
@export var rear_spring_length := 0.2
## How much the spring is compressed when the vehicle is at rest.
## This is used to calculate the approriate spring rate for the wheel.
## A value of 1 would be a fully compressed spring. With a value of 0.5 the
## suspension will rest at the center of it's length.
@export var rear_resting_ratio := 0.5
## Damping ratio is used to calculate the damping forces on the spring.
## A value of 1 would be critically damped. Passenger cars typically have a
## ratio around 0.3, while a race car could be as high as 0.9.
@export var rear_damping_ratio := 0.4
## Bump damping multiplier applied to the damping force calulated from the
## damping ratio. A typical ratio for a passenger car is 2/3 bump damping to
## 3/2 rebound damping. Race cars typically run 3/2 bump to 2/3 rebound.
@export var rear_bump_damp_multiplier := 0.6667
## Rebound damping multiplier applied to the damping force calulated from the
## damping ratio. A typical ratio for a passenger car is 2/3 bump damping to
## 3/2 rebound damping. Race cars typically run 3/2 bump to 2/3 rebound.
@export var rear_rebound_damp_multiplier := 1.5
## Antiroll bar stiffness as a ratio to spring stiffness.
@export var rear_arb_ratio := 0.25
## Wheel camber isn't simulated, but giving the raycast a slight angle helps
## with simulation stability.
@export var rear_camber := 0.01745329
## Toe of the tires measured in radians.
@export var rear_toe := 0.01
## Multiplier for the force applied when the suspension is fully compressed.
## If the vehicle bounces off large bumps, reducing this will help.
@export var rear_bump_stop_multiplier := 1.0
## If true the wheels of this axle will be aligned as if they were attached to
## a beam axle. This setting does not affect vehicle handling.
@export var rear_beam_axle := false

@export_group("Tires")
## Represents the length of the tire contact patch in the brush tire model.
@export var contact_patch := 0.2
## Provides additional longitudinal grip when braking.
@export var braking_grip_multiplier := 1.5
## Tire force applied to the ground is also applied to the vehicle body as a
## torque centered on the wheel. 
@export var wheel_to_body_torque_multiplier := 1.0
## Represents tire stiffness in the brush tire model. Higher values increase
## the responsivness of the tire.
## Surface detection uses node groups to identify the surface, so make sure
## your staticbodies and rigidbodies belong to one of these groups.
@export var tire_stiffnesses := { "Road" : 10.0, "Dirt" : 0.5, "Grass" : 0.5 }
## A multiplier for the amount of force a tire can apply based on the surface.
## Surface detection uses node groups to identify the surface, so make sure
## your staticbodies and rigidbodies belong to one of these groups.
@export var coefficient_of_friction := { "Road" : 3.0, "Dirt" : 2.4, "Grass" : 2.0 }
## A multiplier for the amount of rolling resistance force based on the surface.
## Surface detection uses node groups to identify the surface, so make sure
## your staticbodies and rigidbodies belong to one of these groups.
@export var rolling_resistance := { "Road" : 1.0, "Dirt" : 2.0, "Grass" : 4.0 }
## A multiplier to provide more grip based on the amount of lateral wheel slip.
## This can be used to keep vehicles from sliding a long distance, but may provide
## unrealistically high amounts of grip.
## Surface detection uses node groups to identify the surface, so make sure
## your staticbodies and rigidbodies belong to one of these groups.
@export var lateral_grip_assist := { "Road" : 0.05, "Dirt" : 0.0, "Grass" : 0.0}
## A multiplier to adjust longitudinal grip to differ from lateral grip.
## Useful for allowing vehicles to have wheel spin and maintain high lateral grip.
## Surface detection uses node groups to identify the surface, so make sure
## your staticbodies and rigidbodies belong to one of these groups.
@export var longitudinal_grip_ratio := { "Road" : 0.5, "Dirt": 0.5, "Grass" : 0.5}


#@export_group("Aerodynamics")
### Coefficient of Drag
#@export var coefficient_of_drag := 0.3
### Air Density
#@export var air_density := 1.225
### Frontal area of the car in meters squared.
#@export var frontal_area := 2.0

const ANGULAR_VELOCITY_TO_RPM := 60.0 / TAU

#var wheel_array : Array[Wheel] = []
#var axles : Array[Axle] = []
#var front_axle : Axle
#var rear_axle : Axle
#var drive_wheels : Array[Wheel] = []

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
#var clutch_amount := 0.0
#var current_gear := 0
#var requested_gear := 0
var torque_output := 0.0
#var clutch_torque := 0.0
#var max_clutch_torque := 0.0
#var drive_axles_inertia := 0.0
#var complete_shift_delta_time := 0.0
#var last_shift_delta_time := 0.0
#var average_drive_wheel_radius := 0.0
#var current_torque_split := 0.0
#var true_torque_split := 0.0
var brake_force := 0.0
var max_brake_force := 0.0
var handbrake_force := 0.0
var max_handbrake_force := 0.0
var is_braking := false
#var motor_is_redline := false
#var is_shifting := false
#var is_up_shifting := false
#var need_clutch := false
#var tcs_active := false
#var stability_active := false
#var stability_yaw_torque := 0.0
#var stability_torque_vector := Vector3.ZERO
#var front_axle_position := Vector3.ZERO
#var rear_axle_position := Vector3.ZERO

var delta_time := 0.0

var vehicle_inertia : Vector3



func _ready() -> void:
	default_interaction_property= can_steer


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	wheel= wheel_scene.instantiate()
	wheel.position= position + basis.x
	#wheel.suspension= self
	grid.add_child(wheel)
	wheel.initialize()


func on_destroy():
	wheel.queue_free()
	queue_free()


func on_update():
	if get_parent() != wheel.get_parent():
		wheel.reparent(get_parent())


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var forward_drive: float= max(0, -grid.requested_movement.z)
	var final_brake: float= max(0, grid.requested_movement.z)

	# no braking if we are driving
	if forward_drive > 0:
		final_brake = 0

	throttle_input= forward_drive
	brake_input= final_brake
	steering_input= grid.requested_movement.x

	# brake if movement opposite indended direction
	#if sign(grid.get_current_speed()) != sign(forward_drive) && !is_zero_approx(grid.linear_v) && forward_drive != 0:
	#final_brake = max_braking_coef * abs(forward_drive)
	#final_brake = abs(forward_drive)
		
	## no drive inputs, apply parking brake if sitting still
	#if forward_drive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
		#final_brake = max_braking_coef

	if wheel:
		#if can_steer.is_true():
			#wheel.steer(grid.requested_movement.x)
		#wheel.forward_drive= forward_drive
		#wheel.brake(final_brake)
#
		#if wheel.is_at_travel_limit():
			#grid.add_effect(BlockGridCancelYVelocityEffect.new(pow(1 + wheel.max_travel - wheel.previous_distance, 8) - 1, wheel.previous_hit.hit_normal))
			#wheel.brake(1)
			#DebugHud.send("Over", "%.4f" % ( wheel.max_travel - wheel.previous_distance ))

	
		## For stability calculations, we need the vehicle body inertia which isn't
		## available immidiately
		#if not vehicle_inertia:
		#var rigidbody_inertia := PhysicsServer3D.body_get_direct_state(grid.get_rid()).inverse_inertia.inverse()
		#if rigidbody_inertia.is_finite():
			#vehicle_inertia = rigidbody_inertia * inertia_multiplier
			#assert(vehicle_inertia.x > 0 && vehicle_inertia.y > 0 && vehicle_inertia.z > 0)
			#grid.inertia = vehicle_inertia
		
		delta_time += delta
		local_velocity = lerp(((grid.global_transform.origin - previous_global_position) / delta) * global_transform.basis, local_velocity, 0.5)
		previous_global_position = grid.global_position
		speed = local_velocity.length()
		
		#process_drag()
		process_braking(delta)
		if can_steer.is_true():
			process_steering(delta)
		process_throttle(delta)
		process_motor(delta)
		#process_clutch(delta)
		#process_transmission(delta)
		#process_drive(delta)
		process_forces(grid, delta)
		#process_stability()


#func process_drag() -> void:
	#var drag := 0.5 * air_density * pow(speed, 2.0) * frontal_area * coefficient_of_drag
	#if drag > 0.0:
		#apply_central_force(-local_velocity.normalized() * drag)

func process_braking(delta : float) -> void:
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
	
	brake_force = brake_amount * max_brake_force
	handbrake_force = handbrake_input * max_handbrake_force

func process_steering(delta : float) -> void:
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
	
	## Correct steering toward the direction of travel for countersteer assist
	var steer_correction := (1.0 - absf(steering_adjust)) * clampf(asin(local_velocity.normalized().x), -max_steering_angle, max_steering_angle) * countersteer_assist
	
	## Don't apply corrections at low velocity or reversing
	if local_velocity.z > -0.5:
		steer_correction = 0
	else:
		steer_correction = steer_correction / -max_steering_angle
	
	## Keeps steering corrections from getting stuck under certain circumstances
	var steer_correction_amount := 1.0
	if signf(steering_adjust + steer_correction) != signf(steering_input) and 1.0 - absf(steering_input) < steer_correction_amount:
		steer_correction_amount = clampf(steer_correction_amount - (steering_speed * delta), 0.0, 1.0)
	else:
		steer_correction_amount = clampf(steer_correction_amount + (steering_speed * delta), 0.0, 1.0)
	
	steer_correction *= steer_correction_amount
	
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
	
	## Cut throttle at redline and when shifting
	#if motor_is_redline or is_shifting:
		#throttle_amount = 0.0
	#
	### Disengage clutch when shifting or below motor idle
	#if need_clutch or is_shifting:
		#clutch_amount = 1.0
	#else:
		#clutch_amount = clutch_input


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
	motor_rpm= throttle_amount * 5000


#func process_clutch(delta : float):
	#if current_gear == 0:
		#return
	#
	### Formula to calculate the forces needed to keep the drivetrain and motor closely coupled
	#var current_gear_ratio := get_gear_ratio(current_gear)
	#var drive_inertia := motor_moment + (pow(absf(current_gear_ratio), 2.0) * gear_inertia) + drive_axles_inertia
	#var drive_inertia_R := drive_inertia / (current_gear_ratio * current_gear_ratio)
	#var reaction_torque := get_drive_wheels_reaction_torque() / current_gear_ratio
	#var speed_difference := (motor_rpm / ANGULAR_VELOCITY_TO_RPM) - (get_drivetrain_spin() * current_gear_ratio)
	#if speed_difference < 0.0:
		#speed_difference = -sqrt(-speed_difference)
	#var a := (motor_moment * drive_inertia_R * speed_difference) / delta
	#var b := motor_moment * reaction_torque
	#var c := drive_inertia_R * torque_output
	#var clutch_factor := (1.0 - clutch_amount)
	#var tcs_torque_reduction := 0.0
	#clutch_torque = ((a - b + c)/(motor_moment + drive_inertia_R)) * clutch_factor
	#clutch_torque = clampf(clutch_torque, -max_clutch_torque * clutch_factor, max_clutch_torque * clutch_factor)
	#
	### Check if traction control is needed and adjust motor speed and clutch torque if needed
	#if traction_control_max_slip > 0.0:
		#var slip_y := 0.0
		#for axle in axles:
			#slip_y = maxf(slip_y, axle.get_max_wheel_slip_y())
		#if slip_y > traction_control_max_slip:
			#tcs_torque_reduction = torque_output
			#clutch_torque = 0.0
			#tcs_active = true
		#else:
			#tcs_active = false
	#
	#var clutch_reaction_torque := clutch_torque + tcs_torque_reduction
	#var new_rpm := motor_rpm - ((ANGULAR_VELOCITY_TO_RPM * delta * clutch_reaction_torque) / motor_moment)
	#if new_rpm < idle_rpm:
		#new_rpm = idle_rpm
	#if new_rpm < idle_rpm + 100:
		#need_clutch = true
	#elif new_rpm > clutch_out_rpm:
		#need_clutch = false
	#if new_rpm > max_rpm * 1.1:
		#new_rpm = max_rpm * 1.1
	#
	#motor_rpm = new_rpm

#func process_transmission(delta : float) -> void:
	#if is_shifting:
		#if delta_time > complete_shift_delta_time:
			#complete_shift()
		#return
	#
	### For automatic transmissions to determine when to shift the current wheel speed and 
	### what the wheel speed would be without slip are used. This allows vehicles to spin the
	### tires without immidiately shifting to the next gear.
	#
	#if automatic_transmission:
		#var reversing := false
		#var ideal_wheel_spin := speed / average_drive_wheel_radius
		#var drivetrain_spin := get_drivetrain_spin()
		#var real_wheel_spin := drivetrain_spin * get_gear_ratio(current_gear)
		#var current_ideal_gear_rpm := gear_ratios[current_gear - 1] * final_drive * ideal_wheel_spin * ANGULAR_VELOCITY_TO_RPM
		#var current_real_gear_rpm := real_wheel_spin * ANGULAR_VELOCITY_TO_RPM
		#
		#if current_gear == -1:
			#reversing = true
		#
		#if not reversing:
			#var next_gear_rpm := 0.0
			#if current_gear < gear_ratios.size():
				#next_gear_rpm = get_gear_ratio(current_gear + 1) * ideal_wheel_spin * ANGULAR_VELOCITY_TO_RPM
			#var previous_gear_rpm := 0.0
			#if current_gear - 1 > 0:
				#previous_gear_rpm = get_gear_ratio(current_gear - 1) * maxf(drivetrain_spin, ideal_wheel_spin) * ANGULAR_VELOCITY_TO_RPM
			#
			#
			#if current_gear < gear_ratios.size():
				#if current_gear > 0:
					#if current_ideal_gear_rpm > max_rpm:
						#if delta_time - last_shift_delta_time > shift_time:
							#shift(1)
					#if current_ideal_gear_rpm > max_rpm * 0.8 and current_real_gear_rpm > max_rpm:
						#if delta_time - last_shift_delta_time > shift_time:
							#shift(1)
				#elif current_gear == 0 and motor_rpm > clutch_out_rpm:
					#shift(1)
			#if current_gear - 1 > 0:
				#if current_gear > 1 and previous_gear_rpm < 0.75 * max_rpm:
					#if delta_time - last_shift_delta_time > shift_time:
						#shift(-1)
		#
		#if absf(current_gear) <= 1 and brake_input > 0.75:
			#if not reversing:
				#if speed < 1.0 or local_velocity.z > 0.0:
					#if delta_time - last_shift_delta_time > shift_time:
						#shift(-1)
			#else:
				#if speed < 1.0 or local_velocity.z < 0.0:
					#if delta_time - last_shift_delta_time > shift_time:
						#shift(1)

#func process_drive(delta : float) -> void:
	#var current_gear_ratio := get_gear_ratio(current_gear)
	#var drive_torque := 0.0
	#var drive_inertia := motor_moment + pow(current_gear_ratio, 2) * gear_inertia
	#var max_drive_torque := 0.0
	#var is_slipping := get_is_a_wheel_slipping()
	#
	#if current_gear != 0:
		#drive_torque = clutch_torque * current_gear_ratio
	#
	### Check for slip and adjust variable torque split
	#if variable_torque_split:
		#if is_slipping and throttle_amount > 0.1:
			#current_torque_split = clampf(current_torque_split + (delta / variable_split_speed), 0.0, 1.0)
		#else:
			#current_torque_split = clampf(current_torque_split - (delta / variable_split_speed), 0.0, 1.0)
	#
	### Same formula to keep the motor and drivetrain couple, but to keep the front and rear axles
	### coupled. Modified to allow for a torque split.
	#true_torque_split = lerpf(front_torque_split, front_variable_split, current_torque_split)
	#var axle_a := front_axle
	#var axle_b := rear_axle
	#if true_torque_split <= 0.5:
		#axle_a = rear_axle
		#axle_b = front_axle
	#var axle_difference := axle_a.get_spin() - axle_b.get_spin()
	#var a : float = (axle_a.inertia * axle_b.inertia * axle_difference) / delta
	#var b : float = axle_a.inertia
	#var c : float = axle_b.inertia * drive_torque
	#var transfer_torque := (a - b + c)/(axle_a.inertia + axle_b.inertia)
	#transfer_torque = clampf(transfer_torque, -absf(drive_torque), absf(drive_torque)) * (1.0 - absf((0.5 - true_torque_split) * 2.0))
	#var transfer_torque_2 := drive_torque - transfer_torque
	#
	#process_axle_drive(axle_b, transfer_torque, drive_inertia, delta)
	#process_axle_drive(axle_a, transfer_torque_2, drive_inertia, delta)
#
#func process_axle_drive(axle : Axle, torque : float, drive_inertia : float, delta : float) -> void:
	#if not axle.is_drive_axle:
		#torque = 0.0
		#drive_inertia = 0.0
	#
	#var abs := true
	#
	### If the handbrake in engaged, disable the antilock brakes
	#if axle.handbrake:
		#brake_force += handbrake_force
		#abs = false
	#
	### If enough torque is applied to the axle, lock to wheel speeds and add
	### torque vectoring
	#if axle.is_drive_axle and axle.differential_lock_torque >= 0.0:
		#if absf(torque) > axle.differential_lock_torque:
			#axle.rotation_split = 0.5 + (axle.torque_vectoring * -steering_input)
			#var couple_spin := axle.get_average_spin()
			#axle.wheels[0].spin = couple_spin * axle.rotation_split * 2.0
			#axle.wheels[1].spin = couple_spin * (1.0 - axle.rotation_split) * 2.0
			#axle.rotation_split = (axle.rotation_split * 2.0) - 1.0
		#elif torque != 0.0:
			#var left_reaction_torque_ratio := -absf((axle.wheels[0].get_reaction_torque()) / torque)
			#var right_reaction_torque_ratio := absf((axle.wheels[1].get_reaction_torque()) / torque)
			#axle.rotation_split = maxf(axle.rotation_split, left_reaction_torque_ratio)
			#axle.rotation_split = minf(axle.rotation_split, right_reaction_torque_ratio)
	#
	#var rotation_sum := 0.0
	#var split := (axle.rotation_split + 1.0) * 0.5
	#axle.applied_split = axle.rotation_split
	#rotation_sum += axle.wheels[0].process_torque(torque * split, drive_inertia, brake_force * 0.5 * axle.brake_bias, abs, delta)
	#rotation_sum += axle.wheels[1].process_torque(torque * (1.0 - split), drive_inertia, brake_force * 0.5 * axle.brake_bias, abs, delta)
	#axle.rotation_split = clampf(rotation_sum, -1.0, 1.0)

func process_forces(grid: BlockGrid, delta : float) -> void:
	## Spring compression values are kept for antiroll bar calculations
	#for axle in axles:
		#var previous_compression_left : float = axle.suspension_compression_left
		#axle.suspension_compression_left = axle.wheels[0].process_forces(axle.suspension_compression_right, is_braking, delta)
		#axle.suspension_compression_right = axle.wheels[1].process_forces(previous_compression_left, is_braking, delta)
	#wheel.process_forces(suspension_compression, is_braking, delta)
	wheel.process_forces(grid, 0, is_braking, delta)


#func process_stability() -> void:
	#var is_stability_on := false
	### Calculates the angle of the vehicle in relation to the direction of travel
	### and applies necessary stabilizing forces.
	#if enable_stability:
		#stability_yaw_torque = 0.0
		#var plane_xz := Vector2(local_velocity.x, local_velocity.z)
		#if plane_xz.y < 0 and plane_xz.length() > 1.0:
			#plane_xz = plane_xz.normalized()
			#var yaw_angle := 1.0 - absf(plane_xz.dot(Vector2.UP))
			#if yaw_angle > stability_yaw_engage_angle and signf(angular_velocity.y) == signf(plane_xz.x):
				#stability_yaw_torque = (yaw_angle - stability_yaw_engage_angle) * stability_yaw_strength
				#stability_yaw_torque *= vehicle_inertia.y * clampf(absf(angular_velocity.y) - 0.5, 0.0, 1.0)
		#
		#stability_torque_vector = Vector3.ZERO
		#if get_wheel_contact_count() < 3:
			#stability_torque_vector = (global_transform.basis.y.cross(Vector3.UP) * vehicle_inertia * stability_upright_spring) + (-angular_velocity * stability_upright_damping)
			#apply_torque(stability_torque_vector)
		#else:
			#stability_yaw_torque *= stability_yaw_ground_multiplier
		#
		#if stability_yaw_torque:
			#is_stability_on = true
			#stability_yaw_torque *= signf(-local_velocity.x)
			#apply_torque(global_transform.basis.y * stability_yaw_torque)
	#
	#stability_active = is_stability_on


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

func calculate_brake_force(grid: BlockGrid) -> void:
	#var friction := calculate_average_tire_friction(vehicle_mass * 9.8, "Road")
	var friction := calculate_average_tire_friction(grid.mass * grid.current_gravity.dot(-global_basis.y), "Road")
	#max_brake_force = ((friction * braking_grip_multiplier) * average_drive_wheel_radius) / wheel_array.size()
	max_brake_force = ((friction * braking_grip_multiplier) * wheel.tire_radius)
	#max_handbrake_force = ((friction * braking_grip_multiplier * 0.05) / average_drive_wheel_radius)

#func calculate_center_of_gravity(front_distribution : float) -> Vector3:
	#front_axle_position = front_left_wheel.position.lerp(front_right_wheel.position, 0.5)
	#rear_axle_position = rear_left_wheel.position.lerp(rear_right_wheel.position, 0.5)
	#return lerp(rear_axle_position, front_axle_position, front_distribution)


func calculate_spring_rate(weight : float, spring_length : float, resting_ratio : float) -> float:
	var corrected_resting_ratio := (spring_length * resting_ratio) / spring_length
	var target_compression := spring_length * corrected_resting_ratio * 1000.0
	return weight / target_compression


func calculate_damping(weight : float, spring_rate : float, damping_ratio : float) -> float:
	return damping_ratio * 2.0 * sqrt(spring_rate * weight) * 0.01


func calculate_axle_spring_force(compression : float, spring_length : float, spring_rate : float) -> float:
	return spring_length * compression * 1000.0 * spring_rate * 2.0
