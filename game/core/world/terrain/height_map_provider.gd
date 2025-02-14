class_name HeightMapProvider
extends Node

@export var generator: TerrainGenerator

var terrain: MyTerrain
var terrain_scale: float

var cached_heights: Dictionary



func _ready():
	terrain= get_parent()
	terrain_scale= terrain.scale.x
	assert(terrain)
	pre_generate(1024)


func get_height(x: float, z: float)-> float:
	var pos: Vector2i= Vector2(x,z).round()
	if cached_heights.has(pos):
		return cached_heights[pos]
	return 0
	#return generator.get_height(x, z)


func get_normal(x: float, z: float)-> Vector3:
	return Vector3.UP


func pre_generate(radius: int, origin: Vector2i= Vector2i.ZERO):
	var timer:= Stopwatch.new()
	for x in range(origin.x - radius, origin.x + radius):
		for z in range(origin.y - radius, origin.y + radius):
			cached_heights[Vector2i(x, z)]= generator.get_height(x, z)
	timer.stop("Pre-caching terrain height")
