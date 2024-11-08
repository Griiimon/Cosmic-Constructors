extends Node3D

@export var rotation_speed: float= 5.0

@onready var cooldown: Timer = $Cooldown
@onready var terrain_shapecast: ShapeCast3D = $"Terrain ShapeCast"
@onready var drill_head: MeshInstance3D = $"Drill Head"



func _process(delta: float) -> void:
	drill_head.rotate_z(rotation_speed * delta)


func _physics_process(delta: float) -> void:
	if cooldown.is_stopped():
		if terrain_shapecast.is_colliding():
			var terrain: VoxelLodTerrain= terrain_shapecast.get_collider(0)
			var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
			tool.channel= VoxelBuffer.CHANNEL_SDF
			tool.mode= VoxelTool.MODE_REMOVE
			var radius: float= (terrain_shapecast.shape as SphereShape3D).radius
			tool.do_sphere(terrain.to_local(terrain_shapecast.get_collision_point(0)), radius)
	
		cooldown.start()
