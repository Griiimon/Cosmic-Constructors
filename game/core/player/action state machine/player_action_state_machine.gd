class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionIdleState = $Idle
@onready var build_state: PlayerBuildState = $Build
@onready var build_peripheral_entity_state: PlayerBuildPeripheralEntityState = $"Build Peripheral Entity"



func _ready() -> void:
	idle_state.build_block.connect(change_state.bind(build_state))
	idle_state.build_peripheral_entity.connect(change_state.bind(build_peripheral_entity_state))

	build_state.finished.connect(change_state.bind(idle_state))
	build_peripheral_entity_state.finished.connect(change_state.bind(idle_state))
