class_name ThirdPersonCamera
extends Node3D

@export var scroll_steps: float= 0.1
@export var sensitivity: float= 0.2

@onready var pivot: Node3D = $Pivot
@onready var raycast: RayCast3D = $"Pivot/Third Person Camera RayCast"
@onready var camera: Camera3D = $"Pivot/Third Person Camera"



func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if raycast.target_position.length() < 2: return
				raycast.target_position-= raycast.target_position.normalized() * scroll_steps
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				raycast.target_position+= raycast.target_position.normalized() * scroll_steps

	elif event is InputEventMouseMotion:
		if event.alt_pressed:
			rotate_y(deg_to_rad(-event.relative.x) * sensitivity)
			pivot.rotate_x(deg_to_rad(event.relative.y) * sensitivity)


func update():
	if not is_current(): return
	
	if raycast.is_colliding():
		camera.global_position= raycast.get_collision_point()
	else:
		camera.position= raycast.target_position


func make_current():
	camera.make_current()


func is_current()-> bool:
	return camera.current 
