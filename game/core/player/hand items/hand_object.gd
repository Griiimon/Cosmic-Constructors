class_name HandObject
extends Node3D

var item_definition: HandItem
var animation_player: AnimationPlayer



func _ready() -> void:
	animation_player= get_node_or_null("AnimationPlayer")

	for child in find_children("*", "MeshInstance3D"):
		child.layers = 2


func use():
	if animation_player:
		animation_player.play("use")


func start_using():
	if animation_player:
		animation_player.play("use")


func stop_using():
	if animation_player:
		animation_player.play("RESET")
