class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionIdleState = $Idle
@onready var build_state: PlayerBuildState = $Build
@onready var build_peripheral_entity_state: PlayerBuildPeripheralEntityState = $"Build Peripheral Entity"
@onready var attach_rope_state: PlayerAttachRopeState = $"Attach Rope"



func _ready() -> void:
	idle_state.build_block.connect(change_state.bind(build_state))
	idle_state.build_peripheral_entity.connect(change_state.bind(build_peripheral_entity_state))

	build_state.finished.connect(change_state.bind(idle_state))
	build_peripheral_entity_state.finished.connect(change_state.bind(idle_state))


func attach_rope(from: Vector3)-> Rope:
	var rope: Rope= player.world.make_rope(from, player.misc_item_holder.global_position)
	change_state(attach_rope_state)
	return rope
