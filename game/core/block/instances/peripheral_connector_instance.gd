class_name PeripheralConnectorInstance
extends BlockInstanceOnOff

enum State { IDLE, READY, CONNECTED }

@export var light_material_disabled: StandardMaterial3D
@export var light_material_ready: StandardMaterial3D
@export var light_material_connected: StandardMaterial3D

@onready var joint: JoltHingeJoint3D = $"Fixed Joint"
@onready var detection_area: Area3D = $"Detection Area"
@onready var light: MeshInstance3D = $Light

var state: State= State.IDLE: set= set_state



func set_state(s: State):
	if state == s:
		return
	var prev_state= state
	state= s
	
	
	match state:
		State.IDLE:
			joint.node_b= ""
			light.mesh.surface_set_material(0,light_material_disabled)
		State.READY:
			joint.node_b= ""
			light.mesh.surface_set_material(0,light_material_ready)
		State.CONNECTED:
			assert(detection_area.has_overlapping_areas())
			var target_area: PeripheralConnectorCounterpart= detection_area.get_overlapping_areas()[0]
			assert(target_area)
			joint.node_b= joint.get_path_to(target_area.body)
			light.mesh.surface_set_material(0,light_material_connected)
	
	if prev_state == State.CONNECTED:
		if detection_area.has_overlapping_areas():
			_on_detection_area_area_entered(detection_area.get_overlapping_areas()[0])


func _on_detection_area_area_entered(area: Area3D) -> void:
	set_state.call_deferred(State.READY)
