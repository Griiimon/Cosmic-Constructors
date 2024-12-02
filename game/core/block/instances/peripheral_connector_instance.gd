class_name PeripheralConnectorInstance
extends BlockInstance

enum State { IDLE, READY, CONNECTED }

@export var light_material_disabled: StandardMaterial3D
@export var light_material_ready: StandardMaterial3D
@export var light_material_connected: StandardMaterial3D

@onready var locked:= BlockPropBool.new("Locked", false, on_set_locked)

@onready var joint: JoltHingeJoint3D = $"Fixed Joint"
@onready var detection_area: Area3D = $"Detection Area"
@onready var light: MeshInstance3D = $Light

var state: State= State.IDLE: set= set_state



func _ready() -> void:
	default_interaction_property= locked


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	joint.node_a= joint.get_path_to(grid)
	joint.enabled= false


func set_state(s: State):
	if state == s:
		return
	var prev_state= state
	state= s
	
	
	match state:
		State.IDLE:
			joint.node_b= ""
			joint.enabled= false
			light.mesh.surface_set_material(0,light_material_disabled)
		State.READY:
			light.mesh.surface_set_material(0,light_material_ready)
		State.CONNECTED:
			assert(detection_area.has_overlapping_areas())
			var target_area: PeripheralConnectorCounterpart= detection_area.get_overlapping_areas()[0]
			assert(target_area)
			joint.enabled= true
			joint.node_b= joint.get_path_to(target_area.body)
			light.mesh.surface_set_material(0,light_material_connected)
	
	if prev_state == State.CONNECTED:
		if detection_area.has_overlapping_areas():
			_on_detection_area_area_entered(detection_area.get_overlapping_areas()[0])


func on_set_locked():
	if locked.is_true(): 
		if state == State.READY:
			set_state(State.CONNECTED)
		else:
			locked.set_false()
	else:
		if state == State.CONNECTED:
			set_state(State.IDLE)


func _on_detection_area_area_entered(area: Area3D) -> void:
	if state == State.CONNECTED: return
	set_state.call_deferred(State.READY)


func _on_detection_area_area_exited(area: Area3D) -> void:
	if state == State.CONNECTED: return
	set_state.call_deferred(State.IDLE)
