class_name Player
extends Entity

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"



func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED
