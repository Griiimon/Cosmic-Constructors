class_name Game
extends Node3D

@export var gravity: float

@onready var player: Player = $Player
@onready var world: World = $World



func _init():
	Global.game= self


func _ready() -> void:
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity)
