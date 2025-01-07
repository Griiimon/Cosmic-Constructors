class_name PlayerStateMachineState
extends StateMachineState

@export var player: Player


func _ready() -> void:
	if not player:
		player= get_parent().get_parent()


func on_enter_first_person():
	pass

func on_enter_third_person():
	pass
