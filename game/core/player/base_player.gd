class_name BasePlayer
extends Entity

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@onready var model: PlayerModel = %Model

var last_position: Vector3
var last_velocity: Vector3



func _ready() -> void:
	await get_tree().process_frame
	ClientManager.request_full_peer_sync.rpc_id(get_peer_id())
	last_position= global_position


func _physics_process(delta: float) -> void:
	last_velocity= (global_position - last_position) / delta
	last_position= global_position


func play_animation(anim_name: String, speed: float= 1.0):
	model.play_animation(anim_name, speed)


func reset_animation():
	model.reset_animation()
	set_leg_animation_speed(1.0)


func set_leg_animation_speed(speed: float):
	model.animation_player_legs.speed_scale= speed


func wear_equipment(item: PlayerEquipmentItem)-> PlayerEquipmentObject:
	if item.scene:
		var obj: PlayerEquipmentObject= item.scene.instantiate()
		model.equipment.add_child(obj)
		return obj
	return null


func put_in_seat(seat: SeatInstance): 
	freeze_mode= RigidBody3D.FREEZE_MODE_STATIC
	freeze= true
	collision_shape.disabled= true
	await get_tree().physics_frame

	reparent(seat, false)
	transform= Transform3D.IDENTITY
	if seat.player_position:
		position= seat.player_position.position


func leave_seat(grid: BlockGrid= null, exit_pos= null):
	reparent(get_tree().current_scene)
	get_tree().current_scene.move_child(self, 0)
	if grid and exit_pos:
		global_position= grid.to_global(exit_pos)

	await get_tree().physics_frame
	freeze= false
	collision_shape.disabled= false


func get_peer_id()-> int:
	return int(str(name))


func get_velocity()-> Vector3:
	return last_velocity


func in_gravity()-> bool:
	# FIXME making too many assumptions here
	return is_zero_approx(gravity_scale) or get_gravity().length() > 0
