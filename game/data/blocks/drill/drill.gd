extends Node3D

@export var rotation_speed: float= 5.0

@onready var cooldown: Timer = $Cooldown
@onready var terrain_raycast: RayCast3D = $"Terrain RayCast"
@onready var drill_head: MeshInstance3D = $"Drill Head"



func _process(delta: float) -> void:
	drill_head.rotate_z(rotation_speed * delta)


func _physics_process(delta: float) -> void:
	if cooldown.is_stopped():
		if terrain_raycast.is_colliding():
			var terrain: VoxelLodTerrain= terrain_raycast.get_collider()
			var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
			tool.channel= VoxelBuffer.CHANNEL_SDF
			tool.mode= VoxelTool.MODE_REMOVE
			tool.do_sphere(terrain.to_local(to_global(terrain_raycast.target_position)), 2)
	
		cooldown.start()
