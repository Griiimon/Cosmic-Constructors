class_name Player
extends Entity

@export var world: World

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@onready var build_raycast: RayCast3D = %"Build Raycast"
@onready var interact_shapecast: ShapeCast3D = %"Interact Shapecast"
@onready var floor_shapecast: ShapeCast3D = $"Floor Shapecast"
@onready var block_interact_raycast: RayCast3D = %"Block Interact Raycast"

@onready var head: Node3D = $Head
@onready var first_person_camera: Camera3D = %"First Person Camera"
@onready var pivot: Node3D = %Pivot

@onready var model: Node3D = %Model

@onready var third_person_camera_pivot: Node3D = $"Third Person Camera Pivot"
@onready var third_person_camera_raycast: RayCast3D = $"Third Person Camera Pivot/Third Person Camera RayCast"
@onready var third_person_camera: Camera3D = $"Third Person Camera Pivot/Third Person Camera"

@onready var movement_state_machine: PlayerMovementStateMachine = $"Movement State Machine"
@onready var action_state_machine: PlayerActionStateMachine = $"Action State Machine"

@onready var hand_item_container: Node3D = %"Hand Item Container"
@onready var drill_shapecast: ShapeCast3D = %"Drill Shapecast"

@onready var item_camera: Camera3D = %"Item Camera"


var hand_object: HandObject



func _ready() -> void:
	assert(world)
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED


func sit(seat: SeatInstance):
	movement_state_machine.sit(seat)


func reset_camera():
	head.rotation= Vector3.ZERO
	pivot.rotation= Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_camera"):
		if first_person_camera.current:
			third_person_camera.make_current()
			third_person_camera_pivot.reparent(head)
			model.show()
		else:
			first_person_camera.make_current()
			third_person_camera_pivot.reparent(self)
			model.hide()
			
	if third_person_camera.current:
		if third_person_camera_raycast.is_colliding():
			third_person_camera.global_position= third_person_camera_raycast.get_collision_point()
		else:
			third_person_camera.position= third_person_camera_raycast.target_position


func equip_hand_item(hand_item: HandItem):
	action_state_machine.idle_state.equip_hand_item(hand_item)


func drill():
	action_state_machine.idle_state.drill()


func get_hand_item()-> HandItem:
	if not hand_object or not is_instance_valid(hand_object) or hand_object.is_queued_for_deletion():
		return null
	return hand_object.item_definition
