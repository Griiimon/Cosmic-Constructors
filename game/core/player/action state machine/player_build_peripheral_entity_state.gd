class_name PlayerBuildPeripheralEntityState
extends PlayerActionStateMachineState

@export var rotation_speed: float= 2.0
@export var current_entity: PeripheralEntity:
	set(e):
		current_entity= e
		if not is_inside_tree(): return
		if current_entity:
			update_model()
			init_ghost(model)

var model: PeripheralEntityModel
var aabb: CollisionShape3D



func on_enter():
	var shapecast: ShapeCast3D= player.build_peripheral_entity_shapecast
	shapecast.enabled= true
	
	if current_entity:
		update_model()
		init_ghost(model)


func on_exit():
	var shapecast: ShapeCast3D= player.build_peripheral_entity_shapecast
	shapecast.enabled= false
	remove_ghost()


func on_physics_process(delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("build"):
		finished.emit()
		return
	
	if not ghost: return

	var shapecast: ShapeCast3D= player.build_peripheral_entity_shapecast

	if shapecast.is_colliding():
		ghost.global_position= shapecast.get_collision_point(0)
	else:
		ghost.global_position= shapecast.to_global(shapecast.target_position)
		


	if Input.is_action_just_pressed("build_block"):
		build_entity()
		return
	#elif Input.is_action_just_pressed("pick_block"):
		#pick_block()
		#return

	rotate_ghost(delta)

	ghost.show()


func build_entity():
	player.world.spawn_peripheral_entity(current_entity, ghost.global_position + aabb.position * ghost.global_basis, ghost.rotation)


func rotate_ghost(delta):
	pass


func update_model():
	model= current_entity.get_model()
	aabb= model.find_child("AABB")
	player.build_peripheral_entity_shapecast.shape= aabb.shape
	
