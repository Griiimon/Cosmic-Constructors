class_name Rope
extends Node3D

@export var start: Node3D
@export var end: Node3D
@export var num_segments: int= 10

@export var segment_scene: PackedScene

var material: StandardMaterial3D:
	set(m):
		for segment in segments:
			segment.mesh.material= m

var segments: Array[RopeSegment]



func _ready() -> void:
	for i in num_segments:
		var segment: RopeSegment= segment_scene.instantiate()
		segment.position= lerp(start.global_position, end.global_position, i / float(num_segments))
		add_child(segment)
		segments.append(segment)


func _physics_process(delta: float) -> void:
	for i in num_segments:
		var target1: Vector3
		var target2: Vector3
		
		if i == 0:
			target1= start.global_position
		else:
			target1= segments[i - 1].global_position
		
		if i == num_segments - 1:
			target2= end.global_position
		else:
			target2= segments[i + 1].global_position
		
		var segment: RopeSegment= segments[i]
		segment.simulate(target1, target2)
