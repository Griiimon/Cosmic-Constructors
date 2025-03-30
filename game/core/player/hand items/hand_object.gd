class_name HandObject
extends Node3D

@export var animation_player: AnimationPlayer
@export var model_script: HandItemModel

var item_definition: HandItem
var player: Player



func _ready() -> void:
	for child in find_children("*", "MeshInstance3D"):
		child.layers = 2


# FIXME this wont be called currently
func use():
	if animation_player:
		animation_player.play("use")


func start_using():
	if animation_player:
		animation_player.play("use")
	elif model_script:
		model_script.start_primary_use()
		

func stop_using():
	if animation_player:
		animation_player.play("RESET")
	elif model_script:
		model_script.stop_primary_use()
