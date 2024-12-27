class_name RopeSegment
extends RigidBody3D

@export var max_force: float= 10.0
@export_range(0.0, 1.0) var stretchiness: float= 0.1

@onready var visual_node: Node3D = $Visual

var mesh: CylinderMesh



func _ready() -> void:
	visual_node.top_level= true
	mesh= $Visual/MeshInstance3D.mesh


func simulate(from: Vector3, to: Vector3):
	pull(from - global_position)
	pull(to - global_position)
	visual_node.position= lerp(from, to, 0.5)
	visual_node.look_at(to)
	mesh.height= from.distance_to(to)
	

func pull(force: Vector3):
	apply_central_force(pow(force.length() * max_force, lerp(4.0, 1.0, stretchiness)) * force.normalized()) 
