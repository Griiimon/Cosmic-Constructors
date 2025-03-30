class_name HandGrinderModel
extends HandItemModel

@export var max_rotation_speed:= 100.0
@export var acceleration:= 150.0

@onready var blade: MeshInstance3D = $Blade

var using: bool= false
var current_speed: float


func _process(delta: float):
	if using and current_speed < max_rotation_speed:
		current_speed+= acceleration * delta
	elif not using and current_speed > 0:
		current_speed-= acceleration * delta

	current_speed= clampf(current_speed, 0.0, max_rotation_speed)

	if current_speed > 0:
		blade.rotate_y(current_speed * delta)


func start_primary_use():
	using= true


func stop_primary_use():
	using= false
