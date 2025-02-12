class_name Player
extends BasePlayer

@export var world: World
@export var equipment: PlayerEquipment

@onready var build_raycast: RayCast3D = %"Build Raycast"
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

@onready var item_camera: Camera3D = %"Item Camera"

@onready var misc_item_holder: Node3D = %"Misc Item Holder"
@onready var handle_grabber: Node3D = %"Handle Grabber"

@onready var fps_arms: Node3D = $"Head/Pivot/FPS arms"


var hand_object: HandObject
var active_equipment: Array[PlayerEquipmentObject]
var tool_hotbar:= HotbarLayout.new()



func _ready() -> void:
	assert(world)
	Global.player= self
	
	if not equipment:
		equipment= PlayerEquipment.new()
	
	if equipment.back_item:
		wear_equipment(equipment.back_item)
	
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED

	SignalManager.player_spawned.emit()


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


func is_seated()-> bool:
	return movement_state_machine.seated_state.is_current_state()


func is_rigidbody()-> bool:
	return not freeze


func is_in_third_person()-> bool:
	return not first_person_camera.current


func is_jetpack_active()-> bool:
	return movement_state_machine.eva_state.is_current_state() and movement_state_machine.eva_state.jetpack_enabled
