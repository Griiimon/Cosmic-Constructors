extends Node3D

@export var rotation_speed: float= 5.0

@onready var cooldown: Timer = $Cooldown
@onready var drill_area: Area3D = $"Drill Area"
@onready var drill_area_collision_shape: CollisionShape3D = $"Drill Area/CollisionShape3D"
@onready var drill_head: MeshInstance3D = $"Drill Head"



func _process(delta: float) -> void:
	drill_head.rotate_z(rotation_speed * delta)


func _physics_process(delta: float) -> void:
	if cooldown.is_stopped():
		if drill_area.has_overlapping_bodies():
			var terrain: VoxelLodTerrain= drill_area.get_overlapping_bodies()[0]
			var tool: VoxelToolLodTerrain= terrain.get_voxel_tool()
			tool.channel= VoxelBuffer.CHANNEL_SDF
			tool.mode= VoxelTool.MODE_REMOVE
			var radius: float= (drill_area_collision_shape.shape as SphereShape3D).radius
			tool.do_sphere(terrain.to_local(to_global(drill_area.position)), radius)
	
		cooldown.start()
