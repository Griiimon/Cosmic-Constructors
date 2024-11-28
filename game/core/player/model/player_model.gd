class_name PlayerModel
extends Node3D


@onready var animation_player_arms: AnimationPlayer = $"AnimationPlayer Arms"
@onready var animation_player_legs: AnimationPlayer = $"AnimationPlayer Legs"
@onready var equipment: Node3D = $Equipment
@onready var item_holder: Node3D = %"Item Holder"



func play_animation(anim_name: String, speed: float= 1.0):
	if animation_player_arms.has_animation(anim_name):
		animation_player_arms.play(anim_name, -1, speed)
	if animation_player_legs.has_animation(anim_name):
		animation_player_legs.play(anim_name, -1, speed)


func reset_animation():
	animation_player_arms.play("RESET")
	animation_player_legs.play("RESET")


func equip_hand_item(item: HandItem):
	for child in item_holder.get_children():
		child.queue_free()
	
	item_holder.add_child(item.model.instantiate())
	
