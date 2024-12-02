class_name PlayerMovementStateMachine
extends FiniteStateMachine

@export var jump_impulse: float= 5.0

@onready var eva_state: PlayerEvaState = $EVA
@onready var seated_state: PlayerSeatedState = $Seated
@onready var grid_state: PlayerGridMoveState = $Grid
@onready var terrain_state: PlayerTerrainMoveState = $Terrain
@onready var jump_state: PlayerJumpMoveState = $Jump

var player: Player



func _ready() -> void:
	player= get_parent()
	
	eva_state.landed.connect(landed)
	seated_state.finished.connect(change_state.bind(eva_state))
	
	grid_state.jetpack_enabled.connect(init_eva)
	grid_state.jumped.connect(jump)
	
	terrain_state.jetpack_enabled.connect(init_eva)
	terrain_state.jumped.connect(jump)
	
	jump_state.landed.connect(landed)
	jump_state.jetpack_enabled.connect(init_eva)
	
	
func sit(seat: SeatInstance):
	seated_state.seat= seat
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


func on_pre_enter_state():
	player.reset_animation()
