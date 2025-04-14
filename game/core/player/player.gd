class_name Player
extends BasePlayer

@export var world: World
@export var equipment: PlayerEquipment

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var terrain_raycast: RayCast3D = %"Terrain Raycast"
@onready var build_peripheral_entity_shapecast: ShapeCast3D = %"Build Peripheral Entity Shapecast"

@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"
@onready var floor_shapecast: ShapeCast3D = $"Floor Shapecast"
@onready var block_interact_shapecast: ShapeCast3D = %"Block Interact Shapecast"
@onready var item_interact_shapecast: ShapeCast3D = %"Item Interact Shapecast"
@onready var pull_shapecast: ShapeCast3D = %"Pull Shapecast"

@onready var head: Node3D = $Head
@onready var first_person_camera: Camera3D = %"First Person Camera"
@onready var pivot: Node3D = %Pivot

@onready var third_person_camera: ThirdPersonCamera = %"Third Person Camera"

@onready var movement_state_machine: PlayerMovementStateMachine = $"Movement State Machine"
@onready var action_state_machine: PlayerActionStateMachine = $"Action State Machine"

@onready var item_viewport_container: SubViewportContainer = %"Item Viewport Container"
@onready var hand_item_container: Node3D = %"Hand Item Container"
@onready var drill_shapecast: ShapeCast3D = %"Drill Shapecast"
@onready var grind_shapecast: ShapeCast3D = %"Grind Shapecast"


@onready var item_camera: Camera3D = %"Item Camera"

@onready var misc_item_holder: Node3D = %"Misc Item Holder"
@onready var handle_grabber: Node3D = %"Handle Grabber"

@onready var fps_arms: Node3D = $"Head/Pivot/FPS arms"
@onready var voxel_viewer: VoxelViewer = $VoxelViewer
@onready var voxel_viewer_remote_transform: RemoteTransform3D = $RemoteTransform3D

@onready var equipment_port_area: Area3D = %"Equipment Port Area"
@onready var equipment_joint: JoltHingeJoint3D = %"Equipment JoltHingeJoint3D"
@onready var equipment_port_body: CharacterBody3D = %"Equipment Port Body"


var settings: PlayerEntitySettings

var hand_object: HandObject
var active_equipment: Array[PlayerEquipmentObject]
var tool_hotbar:= HotbarLayout.new()

var equipment_grid: BlockGrid
var connected_port_block_instance: GridControlInstance



func _ready() -> void:
	assert(world)
	Global.player= self
	
	if not equipment:
		equipment= PlayerEquipment.new()
	
	if equipment.back_item:
		wear_equipment(equipment.back_item)
	
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED

	# TODO not necessary anymore when this is implemented
	# https://github.com/Zylann/godot_voxel/commit/c4cc6ef4add7754215bf854aa496b6ebe9228c7d
	voxel_viewer.reparent(get_tree().current_scene)
	voxel_viewer_remote_transform.remote_path= voxel_viewer_remote_transform.get_path_to(voxel_viewer)

	equipment_port_area.area_entered.connect(on_equipment_port_entered)
	equipment_port_area.area_exited.connect(on_equipment_port_exited)

	SignalManager.player_spawned.emit(self)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if voxel_viewer and is_instance_valid(voxel_viewer):
				voxel_viewer.queue_free()


func sit(seat_block: GridBlock):
	movement_state_machine.sit(seat_block)


func reset_camera():
	head.rotation= Vector3.ZERO
	pivot.rotation= Vector3.ZERO


func _physics_process(delta: float) -> void:
	super(delta)
	camera_logic()

	DebugHud.send("From origin", int(global_position.length()))

	for equipment_object in active_equipment:
		equipment_object.tick(self, delta)

	if not is_rigidbody() and is_equipment_port_active():
		DebugHud.send("Port force", equipment_joint.get_applied_force())


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	movement_state_machine.on_integrate_forces(state)
	action_state_machine.on_integrate_forces(state)


func camera_logic():
	if Input.is_action_just_pressed("toggle_camera"):
		if is_in_third_person():
			first_person_camera.make_current()
			third_person_camera.set_process_input(false)
			switch_to_first_person()
		else:
			third_person_camera.make_current()
			third_person_camera.set_process_input(true)
			switch_to_third_person()

	third_person_camera.update()


func switch_to_third_person():
	model.show()
	item_viewport_container.hide()
	movement_state_machine.on_enter_third_person()
	action_state_machine.on_enter_third_person()


func switch_to_first_person():
	model.hide()
	item_viewport_container.show()
	movement_state_machine.on_enter_first_person()
	action_state_machine.on_enter_first_person()


func play_animation(anim_name: String, speed: float= 1.0):
	super(anim_name, speed)
	if NetworkManager.is_client:
		ClientManager.send_sync_event(EventSyncState.Type.START_PLAYER_ANIMATION, [anim_name])


func reset_animation():
	super()
	if NetworkManager.is_client:
		ClientManager.send_sync_event(EventSyncState.Type.RESET_PLAYER_ANIMATION)


func equip_hand_item(hand_item: HandItem):
	action_state_machine.idle_state.equip_hand_item(hand_item)
	model.equip_hand_item(hand_item)


func drill():
	action_state_machine.idle_state.drill()


func grind():
	action_state_machine.idle_state.grind()


func attach_rope(from: Node3D)-> Rope:
	if action_state_machine.attach_rope_state.is_current_state():
		action_state_machine.attach_rope_to(from)
		return action_state_machine.attach_rope_state.rope
	else:
		return action_state_machine.attach_rope_from(from)


func get_hand_item()-> HandItem:
	if not hand_object or not is_instance_valid(hand_object) or hand_object.is_queued_for_deletion():
		return null
	return hand_object.item_definition


func wear_equipment(item: PlayerEquipmentItem)-> PlayerEquipmentObject:
	var obj: PlayerEquipmentObject= super(item)
	if not obj: return null
	obj.item= item
	active_equipment.append(obj)
	obj.init(self)
	if NetworkManager.is_client:
		ClientManager.send_sync_event(EventSyncState.Type.WEAR_EQUIPMENT, [item.resource_path])
	return obj


func grab_handles(handles: HandlesInstance):
	action_state_machine.grab_handles(handles)


func toggle_equipment_port():
	if equipment_joint.enabled:
		if is_using_equipment():
			SignalManager.player_use_equipment.emit(false)
			
		equipment_joint.enabled= false
		connected_port_block_instance= null

		remove_collision_exception_with(equipment_grid)
		equipment_grid.remove_collision_exception_with(self)

		equipment_grid= null

		SignalManager.player_equipment_port_disconnected.emit()
		SignalManager.player_equipment_port_connection_available.emit(true)
	elif equipment_port_area.has_overlapping_areas():
		var area: Area3D= equipment_port_area.get_overlapping_areas()[0]
		connected_port_block_instance= area.owner
		assert(connected_port_block_instance)

		equipment_grid= connected_port_block_instance.get_grid()
		equipment_joint.enabled= true
		equipment_joint.node_a= equipment_joint.get_path_to(equipment_joint.get_parent().get_parent())
		equipment_joint.node_b= equipment_joint.get_path_to(equipment_grid)

		add_collision_exception_with(equipment_grid)
		equipment_grid.add_collision_exception_with(self)

		SignalManager.player_equipment_port_connected.emit()


func toggle_equipment():
	if not equipment_grid: return
	assert(not is_using_equipment())

	movement_state_machine.control_grid(equipment_grid, connected_port_block_instance,\
			equipment_grid.get_block_from_global_pos(connected_port_block_instance.global_position))
	SignalManager.player_use_equipment.emit(true)


func make_rigid():
	equipment_joint.node_a= ""
	global_rotation.y= head.global_rotation.y
	head.rotation.y= 0
	freeze= false
	equipment_joint.node_a= equipment_joint.get_path_to(self)


func make_kinematic():
	freeze= true
	equipment_joint.node_a= equipment_joint.get_path_to(equipment_port_body)


func on_equipment_port_entered(area: Area3D):
	if equipment_joint.enabled: return
	SignalManager.player_equipment_port_connection_available.emit(true)


func on_equipment_port_exited(area: Area3D):
	if equipment_joint.enabled: return
	SignalManager.player_equipment_port_connection_available.emit(false)


func serialize()-> Dictionary:
	var data:= {}
	data["name"]= NetworkManager.player_name
	data["tool_hotbar"]= tool_hotbar.serialize()
	data["build_hotbar"]= action_state_machine.build_state.hotbar_layout.serialize()
	return data


func deserialize(data: Dictionary):
	tool_hotbar.deserialize(data["tool_hotbar"], world)
	action_state_machine.build_state.hotbar_layout.deserialize(data["build_hotbar"], world)
	Global.ui.switch_hotbar(tool_hotbar)


func get_look_vec()-> Vector3:
	return -first_person_camera.global_basis.z


func get_look_ahead_pos(distance: float)-> Vector3:
	return head.global_position + get_look_vec() * distance


func get_head_rotation()-> Vector3:
	return head.global_rotation


func get_seat()-> SeatInstance:
	return movement_state_machine.seated_state.seat


func has_jetpack()-> bool:
	if equipment.back_item and equipment.back_item is JetpackEquipmentItem:
		return true
	return false


func has_equipment_port()-> bool:
	return equipment.has_equipment_port


func is_using_equipment()-> bool:
	return movement_state_machine.grid_control_state.is_current_state()


func is_seated()-> bool:
	return movement_state_machine.seated_state.is_current_state()


func is_rigidbody()-> bool:
	return not freeze


func is_in_third_person()-> bool:
	return not first_person_camera.current


func is_jetpack_active()-> bool:
	return movement_state_machine.eva_state.is_current_state() and movement_state_machine.eva_state.jetpack_enabled


func is_equipment_port_active()-> bool:
	return equipment_grid != null
