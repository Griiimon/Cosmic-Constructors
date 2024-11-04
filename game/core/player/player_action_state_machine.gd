class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionStateIdle = $Idle
@onready var build_state: PlayerBuildState = $Build



func _ready() -> void:
	build_state.finished.connect(change_state.bind(idle_state))
