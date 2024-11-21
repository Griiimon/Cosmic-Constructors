class_name PlayerModel
extends Node3D


@onready var animation_player_arms: AnimationPlayer = $"AnimationPlayer Arms"
@onready var animation_player_legs: AnimationPlayer = $"AnimationPlayer Legs"



func play_animation(anim_name: String, speed: float= 1.0):
	if animation_player_arms.has_animation(anim_name):
		animation_player_arms.play(anim_name, -1, speed)
	if animation_player_legs.has_animation(anim_name):
		animation_player_legs.play(anim_name, -1, speed)


func reset_animation():
	animation_player_arms.play("RESET")
	animation_player_legs.play("RESET")
