class_name BasePlayer
extends Entity

@onready var model: PlayerModel = %Model



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
		model.add_child(obj)
		return obj
	return null
