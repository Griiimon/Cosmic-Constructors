class_name BasePlayer
extends Entity

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


func get_peer_id()-> int:
	return int(str(name))


func get_velocity()-> Vector3:
	return last_velocity
