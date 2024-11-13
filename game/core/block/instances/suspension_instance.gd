class_name SuspensionInstance
extends BlockInstance

@export var wheel_scene: PackedScene

var can_steer:= BlockPropBool.new("Steering", true)

var wheel: Wheel



func _ready() -> void:
	default_interaction_property= can_steer


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	wheel= wheel_scene.instantiate()
	wheel.position= position + basis.x
	wheel.suspension= self
	grid.add_child(wheel)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var forward_drive: float= max(0, -grid.requested_movement.z)
	var final_brake: float= max(0, grid.requested_movement.z)

	# no braking if we are driving
	if forward_drive > 0:
		final_brake = 0

	# brake if movement opposite indended direction
	#if sign(grid.get_current_speed()) != sign(forward_drive) && !is_zero_approx(grid.linear_v) && forward_drive != 0:
	#final_brake = max_braking_coef * abs(forward_drive)
	#final_brake = abs(forward_drive)
		
	## no drive inputs, apply parking brake if sitting still
	#if forward_drive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
		#final_brake = max_braking_coef

	if wheel:
		if can_steer.is_true():
			wheel.steer(grid.requested_movement.x)
		wheel.forward_drive= forward_drive
		wheel.brake(final_brake)


func on_destroy():
	wheel.queue_free()
	queue_free()
