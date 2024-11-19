class_name Game
extends Node3D


@onready var player: Player = $Player
@onready var world: World = $World



func _init():
	Global.game= self
