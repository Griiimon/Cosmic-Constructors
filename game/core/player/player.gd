class_name Player
extends Entity

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"

@onready var movement_state_machine: PlayerMovementStateMachine = $"Movement State Machine"
@onready var action_state_machine: PlayerActionStateMachine = $"Action State Machine"


func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED


func sit(seat: SeatInstance):
	movement_state_machine.sit(seat)
