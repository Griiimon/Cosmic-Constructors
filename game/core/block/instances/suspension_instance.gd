class_name SuspensionInstance
extends BlockInstance


@export var is_electric: bool= true
@export var is_right: bool= true
@export var wheel_scene: PackedScene

var can_steer:= BlockPropBool.new("Steering", true)
var invert_steer:= BlockPropBool.new("Invert Steering", false)

var wheel: Wheel

@export_group("Steering")

@export var steering_speed: float= 1.0
@export var max_steering_angle: float= 0.7

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




#region Unimplemented
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
#endregion

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
var throttle_amount := 0.0
var brake_amount := 0.0
var torque_output := 0.0
var brake_force := 0.0
var handbrake_force := 0.0
var max_handbrake_force := 0.0
var is_braking := false


var delta_time := 0.0

var vehicle_inertia : Vector3

var reverse: bool= false

#var input_torque: float= 0.0
var drive_shaft: LinkedDriveShaftGroup

var sync_wheel_steer:= SyncVarFloat.new("steer")
var sync_wheel_spin:= SyncVarFloat.new("spin")



func _ready() -> void:
	super()
	default_interaction_property= can_steer


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	spawn_wheel(grid)
	wheel.initialize()
	var sync_var_target:= SyncVarTargetBlock.create(grid, grid_block)
	sync_wheel_steer.target= sync_var_target
	sync_wheel_spin.target= sync_var_target


func on_placed_client(grid: BlockGrid, grid_block: GridBlock):
	spawn_wheel(grid)
	var sync_var_target:= SyncVarTargetBlock.create(grid, grid_block)
	sync_wheel_steer.target= sync_var_target
	sync_wheel_spin.target= sync_var_target


func spawn_wheel(grid: BlockGrid):
	wheel= wheel_scene.instantiate()
	wheel.position= position + basis.x * (1 if is_right else -1)
	wheel.base_rotation= rotation.y
	grid.add_child(wheel)


func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	wheel.queue_free()
	super(grid, grid_block)


func on_grid_changed():
	if get_parent() != wheel.get_parent():
		wheel.reparent(get_parent())

	wheel.query.exclude= [ get_grid().get_rid() ]
	wheel.rest_query.exclude= [ get_grid().get_rid() ]


func physics_tick(grid: BlockGrid, _grid_block: GridBlock, delta: float):
	if is_electric:
		throttle_input= round(max(0, -grid.requested_local_movement.z))
		brake_input= round(max(0, grid.requested_local_movement.z))
		steering_input= -round(grid.requested_local_movement.x)

	if grid.parking_brake:
		brake_input= 1
		throttle_input= 0
	
	reverse= grid.reverse_mode

	## no drive inputs, apply parking brake if sitting still
	#if forward_drive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
		#final_brake = max_braking_coef

	DebugHud.send("Reverse", reverse)
	DebugHud.send("Throttle", round(throttle_input))
	DebugHud.send("Brake Input", round(brake_input))

	if wheel:
		delta_time += delta
		local_velocity = lerp(((grid.global_transform.origin - previous_global_position) / delta) * global_transform.basis, local_velocity, 0.5)
		previous_global_position = grid.global_position
		speed = local_velocity.length()
		
		#process_drag()
		process_braking(grid, delta)

		if can_steer.is_true():
			process_steering(delta)

		process_throttle(delta)
		process_motor(delta)
		process_drive(reverse, delta)
		process_forces(grid, delta)

		if drive_shaft:
			# TODO i dont think thats correct
			drive_shaft.torque= min(drive_shaft.torque, wheel.spin / wheel.tire_radius)

		if not is_equal_approx(wheel.spin, sync_wheel_spin.get_value()):
			sync_wheel_spin.set_value(wheel.spin)


func client_physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	if ClientManager.has_sync_var(sync_wheel_steer.get_hash()):
		wheel.rotation.y= ClientManager.get_sync_var_value(sync_wheel_steer.get_hash())
	if ClientManager.has_sync_var(sync_wheel_spin.get_hash()):
		wheel.spin= ClientManager.get_sync_var_value(sync_wheel_spin.get_hash())


func has_client_physics_tick()-> bool:
	return true


#func process_drag() -> void:
	#var drag := 0.5 * air_density * pow(speed, 2.0) * frontal_area * coefficient_of_drag
	#if drag > 0.0:
		#apply_central_force(-local_velocity.normalized() * drag)


func process_braking(grid: BlockGrid, delta : float) -> void:
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
	var friction := calculate_average_tire_friction(grid.mass * grid.get_gravity().dot(-global_basis.y), "Road")
	#max_brake_force = ((friction * braking_grip_multiplier) * average_drive_wheel_radius) / wheel_array.size()
	var max_brake_force: float = ((friction * wheel.braking_grip_multiplier) * wheel.tire_radius)
	#max_handbrake_force = ((friction * braking_grip_multiplier * 0.05) / average_drive_wheel_radius)

	brake_force = brake_amount * max_brake_force
	DebugHud.send("Brake", brake_force)
	handbrake_force = handbrake_input * max_handbrake_force


func process_steering(delta : float) -> void:
	if invert_steer.is_true():
		steering_amount= -steering_amount

	var new_steering: float= lerp(steering_amount, steering_input, delta * steering_speed)
	if not is_equal_approx(steering_amount, new_steering):
		steering_amount= new_steering
		wheel.steer(steering_amount, max_steering_angle)
		sync_wheel_steer.set_value(wheel.rotation.y)


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


func process_motor(_delta : float) -> void:
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
	if is_electric:
		motor_rpm= throttle_amount * 1000
	else:
		#motor_rpm= throttle_amount * input_torque
		if drive_shaft:
			motor_rpm= drive_shaft.torque


func process_drive(in_reverse: bool, delta : float) -> void:
	DebugHud.send("RPM", motor_rpm)
	process_axle_drive(motor_rpm, in_reverse, 0, delta)


func process_axle_drive(torque : float, in_reverse: bool, drive_inertia : float, delta : float) -> void:
	wheel.process_torque(torque, in_reverse, drive_inertia, brake_force, false, delta)


func process_forces(grid: BlockGrid, delta : float) -> void:
	wheel.process_forces(grid, is_braking, delta)


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
