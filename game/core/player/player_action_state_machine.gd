class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionIdleState = $Idle
@onready var build_state: PlayerBuildState = $Build



func _ready() -> void:
	idle_state.build.connect(change_state.bind(build_state))
	build_state.finished.connect(change_state.bind(idle_state))
