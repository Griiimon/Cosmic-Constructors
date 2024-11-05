class_name PlayerMovementStateMachine
extends FiniteStateMachine


@onready var eva_state: PlayerEvaState = $EVA
@onready var seated_state: PlayerSeatedState = $Seated
@onready var grid_state: PlayerGridMoveState = $Grid

var player: Player



func _ready() -> void:
	player= get_parent()
	
	eva_state.land.connect(landed)
	seated_state.finished.connect(change_state.bind(eva_state))
	grid_state.jetpack_enabled.connect(change_state.bind(eva_state))

	
func sit(seat: SeatInstance):
	seated_state.seat= seat
	change_state(seated_state)


func landed():
	var collider: PhysicsBody3D= player.floor_shapecast.get_collider(0)
	
	if collider is BlockGrid:
		grid_state.grid= collider
		change_state(grid_state)
