class_name PlayerActionStateMachine
extends FiniteStateMachine

@onready var idle_state: PlayerActionIdleState = $Idle
@onready var build_state: PlayerBuildState = $Build
@onready var build_peripheral_entity_state: PlayerBuildPeripheralEntityState = $"Build Peripheral Entity"
@onready var attach_rope_state: PlayerAttachRopeState = $"Attach Rope"
@onready var carry_item_state: PlayerCarryItemState = $"Carry Item"
@onready var grab_handles_state: PlayerGrabHandlesState = $"Grab Handles"
@onready var pull_state: PlayerPullState = $Pull
@onready var save_blueprint_state: PlayerSaveBlueprintState = $"Save Blueprint"
@onready var load_blueprint_state: PlayerLoadBlueprintState = $"Load Blueprint"

var player: Player



func _ready() -> void:
	player= get_parent()

	state_changed.connect(SignalManager.player_set_action_state.emit)

	idle_state.build_block.connect(change_state.bind(build_state))
	idle_state.build_peripheral_entity.connect(change_state.bind(build_peripheral_entity_state))

	build_state.finished.connect(change_state.bind(idle_state))
	build_peripheral_entity_state.finished.connect(change_state.bind(idle_state))

	carry_item_state.finished.connect(change_state.bind(idle_state))

	grab_handles_state.finished.connect(change_state.bind(idle_state))
	
	pull_state.finished.connect(change_state.bind(idle_state))

	save_blueprint_state.finished.connect(change_state.bind(idle_state))
	load_blueprint_state.finished.connect(change_state.bind(idle_state))


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


func grab_handles(handles: HandlesInstance):
	grab_handles_state.handles= handles
	change_state(grab_handles_state)


func pull(pullable: PullableComponent):
	pull_state.pullable= pullable
	change_state(pull_state)


func save_blueprint(grid: BlockGrid):
	save_blueprint_state.grid= grid
	change_state(save_blueprint_state)


func load_blueprint():
	change_state(load_blueprint_state)


func on_enter_first_person():
	current_state.on_enter_first_person()


func on_enter_third_person():
	current_state.on_enter_third_person()
