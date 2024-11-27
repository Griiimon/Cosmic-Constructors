class_name Player
extends BasePlayer

@export var world: World
@export var equipment: PlayerEquipment

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"
@onready var floor_shapecast: ShapeCast3D = $"Floor Shapecast"
@onready var block_interact_raycast: RayCast3D = %"Block Interact Raycast"

@onready var head: Node3D = $Head
@onready var first_person_camera: Camera3D = %"First Person Camera"
@onready var pivot: Node3D = %Pivot

@onready var third_person_camera_pivot: Node3D = %"Third Person Camera Pivot"
@onready var third_person_camera_raycast: RayCast3D = %"Third Person Camera RayCast"
@onready var third_person_camera: Camera3D = %"Third Person Camera"

@onready var movement_state_machine: PlayerMovementStateMachine = $"Movement State Machine"
@onready var action_state_machine: PlayerActionStateMachine = $"Action State Machine"

@onready var item_viewport_container: SubViewportContainer = %"Item Viewport Container"
@onready var hand_item_container: Node3D = %"Hand Item Container"
@onready var drill_shapecast: ShapeCast3D = %"Drill Shapecast"

@onready var item_camera: Camera3D = %"Item Camera"


var hand_object: HandObject
var active_equipment: Array[PlayerEquipmentObject]



func _ready() -> void:
	assert(world)
	Global.player= self
	
	if not equipment:
		equipment= PlayerEquipment.new()
	
	if equipment.back_item:
		wear_equipment(equipment.back_item)
	
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED

	SignalManager.player_spawned.emit()


func sit(seat: SeatInstance):
	movement_state_machine.sit(seat)


func reset_camera():
	head.rotation= Vector3.ZERO
	pivot.rotation= Vector3.ZERO


func _physics_process(delta: float) -> void:
	camera_logic()

	for equipment_object in active_equipment:
		equipment_object.tick(self, delta)


func camera_logic():
	if Input.is_action_just_pressed("toggle_camera"):
		if first_person_camera.current:
			third_person_camera.make_current()
			third_person_camera_raycast.set_process_input(true)
			model.show()
			item_viewport_container.hide()
		else:
			first_person_camera.make_current()
			third_person_camera_raycast.set_process_input(false)
			model.hide()
			item_viewport_container.show()

	if third_person_camera.current:
		if third_person_camera_raycast.is_colliding():
			third_person_camera.global_position= third_person_camera_raycast.get_collision_point()
		else:
			third_person_camera.position= third_person_camera_raycast.target_position


func play_animation(anim_name: String, speed: float= 1.0):
	super(anim_name, speed)
	ClientManager.send_sync_event(EventSyncState.Type.START_PLAYER_ANIMATION, [anim_name])


func reset_animation():
	super()
	ClientManager.send_sync_event(EventSyncState.Type.RESET_PLAYER_ANIMATION)


func equip_hand_item(hand_item: HandItem):
	action_state_machine.idle_state.equip_hand_item(hand_item)


func drill():
	action_state_machine.idle_state.drill()


func get_hand_item()-> HandItem:
	if not hand_object or not is_instance_valid(hand_object) or hand_object.is_queued_for_deletion():
		return null
	return hand_object.item_definition


func wear_equipment(item: PlayerEquipmentItem)-> PlayerEquipmentObject:
	var obj: PlayerEquipmentObject= super(item)
	if not obj: return null
	active_equipment.append(obj)
	obj.init(self)
	ClientManager.send_sync_event(EventSyncState.Type.WEAR_EQUIPMENT, [item.resource_path])
	return obj
