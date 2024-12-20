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

@onready var pull_area: Area3D = $"Pull Area"


var state: State= State.IDLE: set= set_state



func _ready() -> void:
	default_interaction_property= locked


func on_placed(grid: BlockGrid, _grid_block: GridBlock):
	joint.node_a= joint.get_path_to(grid)
	joint.enabled= false


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if state != State.CONNECTED:
		if pull_area.has_overlapping_areas():
			var counter_part: PeripheralConnectorCounterpart= pull_area.get_overlapping_areas()[0]
			var pull_entity: RigidBody3D= counter_part.body
			
			pull_entity.apply_force((pull_area.global_position - counter_part.global_position) * 1000, counter_part.global_position - pull_entity.global_position)
			
			var quat: Quaternion= pull_area.global_basis.get_rotation_quaternion().inverse() * counter_part.global_basis.get_rotation_quaternion()
			#DebugHud.send("Align Axis", quat.get_axis())
			#DebugHud.send("Align Angle", rad_to_deg(quat.get_angle()))
			pull_entity.apply_torque(quat.get_axis() * quat.get_angle() * 500)


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


func _on_detection_area_area_entered(_area: Area3D) -> void:
	if state == State.CONNECTED: return
	set_state.call_deferred(State.READY)


func _on_detection_area_area_exited(_area: Area3D) -> void:
	if state == State.CONNECTED: return
	set_state.call_deferred(State.IDLE)
