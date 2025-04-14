class_name PlayerMovementStateMachine
extends FiniteStateMachine

@export var jump_impulse: float= 5.0

@onready var eva_state: PlayerEvaState = $EVA
@onready var seated_state: PlayerSeatedState = $Seated
@onready var grid_control_state: PlayerGridControlState = $"Grid Control"
@onready var grid_state: PlayerGridMoveState = $Grid
@onready var terrain_state: PlayerTerrainMoveState = $Terrain
@onready var jump_state: PlayerJumpMoveState = $Jump

var player: Player



func _ready() -> void:
	player= get_parent()
	
	eva_state.landed.connect(landed)
	seated_state.finished.connect(on_left_seat)
	grid_control_state.finished.connect(init_eva)
	
	grid_state.jetpack_enabled.connect(init_eva)
	grid_state.jumped.connect(jump)
	
	terrain_state.jetpack_enabled.connect(init_eva)
	terrain_state.jumped.connect(jump)
	
	jump_state.landed.connect(landed)
	jump_state.jetpack_enabled.connect(init_eva)
	
	
func sit(seat_block: GridBlock):
	seated_state.seat= seat_block.get_block_instance()
	seated_state.seat_block= seat_block
	change_state(seated_state)


func landed():
	var collider: Node3D= player.floor_shapecast.get_collider(0)
	
	if collider is BlockGrid:
		grid_state.grid= collider
		change_state(grid_state)
	else:
		change_state(terrain_state)


func init_eva(force_jetpack: bool= true):
	change_state(eva_state)
	if force_jetpack:
		eva_state.jetpack_active= true
	player.linear_velocity= player.get_velocity()


func jump(impulse: bool= true):
	change_state(jump_state)
	player.linear_velocity= player.get_velocity()

	if impulse:
		player.apply_central_impulse(player.global_basis.y * jump_impulse)
		jump_state.land_cooldown.start()


func control_grid(grid: BlockGrid, control_instance: BlockInstance, control_block: GridBlock):
	grid_control_state.controlled_grid= grid
	grid_control_state.control_instance= control_instance
	grid_control_state.control_block= control_block
	change_state(grid_control_state)


func on_left_seat():
	change_state(eva_state)


func on_pre_enter_state():
	player.reset_animation()


func on_enter_first_person():
	current_state.on_enter_first_person()


func on_enter_third_person():
	current_state.on_enter_third_person()
