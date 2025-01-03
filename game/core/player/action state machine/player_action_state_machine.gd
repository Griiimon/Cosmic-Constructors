class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionIdleState = $Idle
@onready var build_state: PlayerBuildState = $Build
@onready var build_peripheral_entity_state: PlayerBuildPeripheralEntityState = $"Build Peripheral Entity"
@onready var attach_rope_state: PlayerAttachRopeState = $"Attach Rope"
@onready var carry_item_state: PlayerCarryItemState = $"Carry Item"

var player: Player



func _ready() -> void:
	player= get_parent()

	idle_state.build_block.connect(change_state.bind(build_state))
	idle_state.build_peripheral_entity.connect(change_state.bind(build_peripheral_entity_state))

	build_state.finished.connect(change_state.bind(idle_state))
	build_peripheral_entity_state.finished.connect(change_state.bind(idle_state))

	carry_item_state.finished.connect(change_state.bind(idle_state))


func attach_rope_from(from: Node3D)-> Rope:
	var rope: Rope= player.world.make_rope(from, player.misc_item_holder)
	attach_rope_state.rope= rope
	change_state(attach_rope_state)
	return rope


func attach_rope_to(to: Node3D)-> Rope:
	var rope: Rope= attach_rope_state.rope
	rope.end= to
	change_state(idle_state)
	return rope


func pick_up_item(item: WorldItemInstance):
	carry_item_state.item= item
	change_state(carry_item_state)
