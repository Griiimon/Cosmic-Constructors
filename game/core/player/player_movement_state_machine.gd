class_name PlayerMovementStateMachine
extends FiniteStateMachine


@onready var eva_state: PlayerEvaState = $EVA
@onready var seated_state: PlayerSeatedState = $Seated



func sit(seat: SeatInstance):
	seated_state.seat= seat
	change_state(seated_state)
