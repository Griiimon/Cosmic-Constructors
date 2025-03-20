class_name HeightMapProvider
extends Node

@export var generator: TerrainGenerator

var terrain: Node3D
var terrain_scale: float



func _ready():
	terrain= get_parent()
	terrain_scale= terrain.scale.x
	assert(terrain)


func get_height(x: float, z: float)-> float:
	return generator.get_height(x, z)


func get_normal(x: float, z: float)-> Vector3:
	return Vector3.UP
