class_name Game
extends Node3D

@onready var player: Player = $Player

var grids: Node


func _init():
	Global.game= self


func _ready() -> void:
	grids= Node.new()
	grids.name= "Grids"
	add_child(grids)
