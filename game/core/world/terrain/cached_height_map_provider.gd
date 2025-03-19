class_name CachedHeightMapProvider
extends HeightMapProvider

@export var radius: float= 1024
@export var normals_resolution: int= 4


var cached_heights: Dictionary
var cached_normals: Dictionary



func _ready():
	terrain= get_parent()
	terrain_scale= terrain.scale.x
	assert(terrain)
	pre_generate(radius)


func get_height(x: float, z: float)-> float:
	var pos: Vector2i= Vector2(x,z).round()
	if cached_heights.has(pos):
		return cached_heights[pos]
	return 0
	#return generator.get_height(x, z)


func get_normal(x: float, z: float)-> Vector3:
	var normal_coords: Vector2i= Vector2(x, z) / normals_resolution
	if cached_normals.has(normal_coords):
		return cached_normals[normal_coords]
	return Vector3.UP


func pre_generate(radius: int, origin: Vector2i= Vector2i.ZERO):
	var timer:= Stopwatch.new()
	for x in range(origin.x - radius, origin.x + radius):
		for z in range(origin.y - radius, origin.y + radius):
			cached_heights[Vector2i(x, z)]= generator.get_height(x, z)
	timer.stop("Pre-caching terrain height")

	timer= Stopwatch.new()
	for x in range(origin.x - radius + 1, origin.x + radius - 1, normals_resolution):
		for z in range(origin.y - radius + 1, origin.y + radius - 1, normals_resolution):
			var h1: float= cached_heights[Vector2i(x - 1, z)]
			var h2: float= cached_heights[Vector2i(x + 1, z - 1)]
			var h3: float= cached_heights[Vector2i(x + 1, z + 1)]
			
			var plane:= Plane(Vector3((x - 1), h1, z), Vector3((x + 1), h2, (z - 1)), Vector3((x + 1), h3, (z + 1)))

			cached_normals[Vector2i(Vector2(x, z) / float(normals_resolution))]= plane.normal

	timer.stop("Pre-caching normals")
