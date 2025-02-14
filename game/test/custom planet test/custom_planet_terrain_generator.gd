class_name CustomPlanetTerrainGenerator
extends TerrainGenerator

@export var height_noise: FastNoiseLite
@export var height_factor: float= 100.0

@export var slope_stone_threshold: float= 0.8

@export var mountains_noise: FastNoiseLite
@export var mountains_threshold: float= 0.3
@export var mountains_multiplier: float= 5.0

@export var iron_noise1: FastNoiseLite
@export var iron_noise2: FastNoiseLite
@export var iron_noise_weight: float= 0.5
@export var iron_threshold: float= 0.75



func get_height(x: float, z: float)-> float:
	var height := height_noise.get_noise_2d(x, z)
	height*= height
	height*= height_factor
	
	var mountains: float= mountains_noise.get_noise_2d(x, z)
	if abs(mountains) > mountains_threshold:
		var new_height= height * sign(mountains) * mountains_multiplier
		height= lerpf(height, new_height, clampf((abs(mountains) - mountains_threshold) * 10.0, 0.0, 1.0))
	
	return height
