class_name Player
extends Entity

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"
@onready var floor_shapecast: ShapeCast3D = $"Floor Shapecast"

@onready var head: Node3D = $Head
@onready var pivot: Node3D = %Pivot

@onready var movement_state_machine: PlayerMovementStateMachine = $"Movement State Machine"
@onready var action_state_machine: PlayerActionStateMachine = $"Action State Machine"


func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED


func sit(seat: SeatInstance):
	movement_state_machine.sit(seat)


func reset_camera():
	head.rotation= Vector3.ZERO
	pivot.rotation= Vector3.ZERO
