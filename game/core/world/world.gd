class_name World
extends Node3D

const SAVE_FILE_NAME= "user://world.json"

var grids: Node
var projectiles: Node
var grid_freeze_state:= false


func _ready() -> void:
	grids= generate_sub_node("Grids")
	projectiles= generate_sub_node("Projectiles")


func generate_sub_node(node_name: String)-> Node:
	var node:= Node.new()
	node.name= node_name
	add_child(node)
	return node


func add_grid(pos: Vector3, rot: Vector3= Vector3.ZERO)-> BlockGrid:
	var grid:= BlockGrid.new()
	grid.position= pos
	grid.rotation= rot
	grid.world= self
	grids.add_child(grid)
	
	grid.freeze= grid_freeze_state
	
	return grid


func damage_object(obj: Node3D, damage: Damage):
	#if obj.is_in_group(DamageComponent.GROUP_NAME):
		#var damage_component: DamageComponent= DamageComponent.get_component(obj)
		#damage_component.take_damage(dmg)

	var collision_shapes: Array[CollisionShape3D]
	if is_zero_approx(damage.radius):
		collision_shapes.append(obj.find_children("*", "CollisionShape3D")[damage.shape_index])
	else:
		var query:= PhysicsShapeQueryParameters3D.new()
		query.transform.origin= damage.position
		query.shape= SphereShape3D.new()
		query.shape.radius= damage.radius
		
		var result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query, 100)
		if result:
			for item in result:
				prints("Damage object", item.collider.name, ", shape idx", item.shape)
				collision_shapes.append(item.collider.shape_owner_get_owner(item.collider.shape_find_owner(item.shape)))
	
	print("Damage %d shapes" % collision_shapes.size())
	
	collision_shapes.sort_custom(func(a: CollisionShape3D, b: CollisionShape3D):\
	 	return a.global_position.distance_squared_to(damage.position) >\
			b.global_position.distance_squared_to(damage.position))

	RaycastHelper.hit_from_inside= false
	RaycastHelper.hit_back_faces= false
	RaycastHelper.collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER# + Global.TERRAIN_COLLISION_LAYER

	for coll_shape in collision_shapes:
		var result: RaycastHelper.PierceResult= RaycastHelper.pierce(coll_shape.global_position, damage.position)
		if not result.items.is_empty():
			assert(result.items[-1].object == obj)
			result.items.reverse()
			
			var total_damage: int= damage.amount
			
			for pierce_item in result.items:
				var collider: Node3D= pierce_item.object
				if collider.is_in_group(DamageComponent.GROUP_NAME):
					var damage_component: DamageComponent= DamageComponent.get_component(collider)
					total_damage= damage_component.absorb_damage(total_damage, pierce_item.coll_shape)
			
			prints("Total damage %d after piercing through %d" %[total_damage, result.items.size()])
			
			if total_damage > 0:
				var damage_component: DamageComponent= DamageComponent.get_component(coll_shape.get_parent())
				var final_damage: Damage= damage.duplicate()
				final_damage.amount= total_damage
				damage_component.take_damage(final_damage, coll_shape)


func save_world():
	var save_file: FileAccess = FileAccess.open(SAVE_FILE_NAME, FileAccess.WRITE)
	for grid: BlockGrid in grids.get_children():
		var json_string = JSON.stringify(grid.serialize())
		save_file.store_line(json_string)
	save_file.close()


func load_world():
	if not FileAccess.file_exists(SAVE_FILE_NAME):
		return

	var save_file = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var grid_data = json.data

		var grid: BlockGrid= BlockGrid.deserialize(grid_data, self)
		grid.world= self

		grid.update_properties()


func add_projectile(projectile: ProjectileObject):
	projectile.world= self
	projectiles.add_child(projectile)


func freeze_grids(b: bool):
	grid_freeze_state= b
	for grid: BlockGrid in grids.get_children():
		grid.freeze= b
