extends Node3D

@export var move_speed: float= 10.0
@export var mouse_sensitivity: float= 0.1

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D
@onready var ray_cast: RayCast3D = $Pivot/Camera3D/RayCast3D



func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x) * mouse_sensitivity)
		pivot.rotate_x(-deg_to_rad(event.relative.y) * mouse_sensitivity)

	elif event is InputEventMouseButton:
		if event.is_pressed():
			if ray_cast.is_colliding():
				var terrain: VoxelLodTerrain= ray_cast.get_collider()
				var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
				tool.channel= VoxelBuffer.CHANNEL_SDF
				tool.mode= VoxelTool.MODE_REMOVE
				tool.do_sphere(terrain.to_local(ray_cast.get_collision_point()), 2)


func _process(delta: float) -> void:
	var move_inp: Vector2= Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position+= camera.global_basis * Vector3(move_inp.x, 0, move_inp.y) * delta * move_speed
