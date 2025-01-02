class_name World
extends Node3D

const SAVE_FILE_NAME= "world.json"
const WORLD_ITEM_SCENE= preload("res://game/core/world/world item/world_item_instance.tscn")

class DelayedExplosiveForce:
	var damage: Damage
	var countdown: int
	
	func _init(_damage: Damage):
		damage= _damage.duplicate()
		countdown= 2


var grids: Node
var projectiles: Node
var items: Node
var peripheral_entities: Node
var ropes: Node

var grid_freeze_state:= false

var delayed_forces: Array[DelayedExplosiveForce]



func _ready() -> void:
	grids= generate_sub_node("Grids")
	projectiles= generate_sub_node("Projectiles")
	items= generate_sub_node("Items")
	peripheral_entities= generate_sub_node("Peripheral Entities")
	ropes= generate_sub_node("Ropes")


func _physics_process(_delta: float) -> void:
	for force in delayed_forces.duplicate():
		force.countdown-= 1
		if force.countdown == 0:
			delayed_forces.erase(force)
			apply_delayed_explosive_force(force)


func generate_sub_node(node_name: String)-> Node:
	var node:= Node.new()
	node.name= node_name
	add_child(node)
	return node


func add_grid(pos: Vector3, rot: Vector3= Vector3.ZERO)-> BlockGrid:
	var grid:= BlockGrid.new()
	init_grid(grid, pos, rot)
	return grid
	

func init_grid(grid: BlockGrid, pos: Vector3, rot: Vector3):
	grid.position= pos
	grid.rotation= rot
	grid.world= self
	grid.current_gravity= PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR) * PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	grids.add_child(grid)
	
	grid.freeze= grid_freeze_state


# not used
func add_custom_grid(grid: BlockGrid, pos: Vector3, rot: Vector3= Vector3.ZERO)-> BlockGrid:
	init_grid(grid, pos, rot)
	return grid


func damage_point(damage: Damage, obj: CollisionObject3D= null):
	if damage.is_explosion():
		explosion(damage, obj)
		Effects.spawn_explosion(damage.position, damage.radius)
	else:
		damage_object(obj, damage)


func damage_object(obj: CollisionObject3D, damage: Damage):
	var collision_shapes: Array[CollisionShape3D]
	if not is_zero_approx(damage.radius):
		var query:= PhysicsShapeQueryParameters3D.new()
		query.transform.origin= damage.position
		query.shape= SphereShape3D.new()
		query.shape.radius= damage.radius
		
		var shape_result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query, 100)
		if shape_result:
			for item in shape_result:
				if item.collider != obj: continue
				var coll_shape: CollisionShape3D= item.collider.shape_owner_get_owner(item.collider.shape_find_owner(item.shape))
				collision_shapes.append(coll_shape)
				#prints("Damage object %s impact @%s shape #%d @%s" % [str(item.collider.name), str(damage.position), item.shape, str(coll_shape.global_position)])
				#DebugMesh.create(coll_shape.global_position + Vector3.UP, 0.3)
	
		#print("Damage %d shapes" % collision_shapes.size())
		
		collision_shapes.sort_custom(func(a: CollisionShape3D, b: CollisionShape3D):\
		 	return a.global_position.distance_squared_to(damage.position) >\
				b.global_position.distance_squared_to(damage.position))

		RaycastHelper.hit_from_inside= false
		RaycastHelper.hit_back_faces= false
		RaycastHelper.collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER# + Global.TERRAIN_COLLISION_LAYER

		for coll_shape in collision_shapes:
			var ray_origin: Vector3= coll_shape.global_position
			var ray_target: Vector3= damage.position
			var result: RaycastHelper.PierceResult= RaycastHelper.pierce(ray_origin, ray_target)
			if not result.items.is_empty():
				result.items.reverse()
				
				var total_damage: int= damage.amount
				
				for pierce_item in result.items:
					var collider: Node3D= pierce_item.object
					if collider.is_in_group(DamageComponent.GROUP_NAME):
						if collider is BlockGrid:
							var grid: BlockGrid= collider
							var pierced_blocks: Array[Vector3i]= grid.raycast(ray_origin, ray_target)
							pierced_blocks.reverse()
							for block_pos in pierced_blocks:
								var block: BaseGridBlock= grid.get_block_local(block_pos)
								total_damage= block.absorb_damage(total_damage)
				
							#prints(" Total damage %d after piercing through %d blocks" %[total_damage, pierced_blocks.size()])

						else:
							var damage_component: DamageComponent= DamageComponent.get_component(collider)
							total_damage= damage_component.absorb_damage(total_damage, pierce_item.coll_shape)
				
				#prints("Total damage %d @%s after piercing through %d colliders" %[total_damage, str(coll_shape.global_position), result.items.size()])
				
				if total_damage > 0:
					deal_damage_via_collision_shape(damage, coll_shape, total_damage)

	var shape_index: int= damage.shape_index if damage.shape_index > -1 else 0
	var impact_coll_shape: CollisionShape3D= obj.shape_owner_get_owner(obj.shape_find_owner(shape_index))
	deal_damage_via_collision_shape(damage, impact_coll_shape)


func deal_damage_via_collision_shape(orig_damage: Damage, coll_shape: CollisionShape3D, custom_amount: int = -1):
	var damage_component: DamageComponent= DamageComponent.get_component(coll_shape.get_parent())
	if damage_component:
		var final_damage: Damage= orig_damage.duplicate()
		if custom_amount > -1:
			final_damage.amount= custom_amount
		damage_component.take_damage(final_damage, coll_shape)


func apply_delayed_explosive_force(force: DelayedExplosiveForce):
	var center: Vector3= force.damage.position

	var query:= PhysicsShapeQueryParameters3D.new()
	query.transform.origin= center
	query.collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER
	var shape:= SphereShape3D.new()
	shape.radius= force.damage.radius
	query.shape= shape
	
	var result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query)
	if result:
		var rid_map: Dictionary
		var rid_closes_point: Dictionary
		for item: Dictionary in result:
			var collider: CollisionObject3D= item.collider
			if collider is not BlockGrid: continue
			
			var rid: RID= collider.get_rid() 
		
			if not rid_map.has(rid):
				rid_map[rid]= collider
				rid_closes_point[rid]= null
			
			var coll_shape: CollisionShape3D= collider.shape_owner_get_owner(collider.shape_find_owner(item.shape))
			var point: Vector3= coll_shape.global_position
			
			if rid_closes_point[rid] == null or center.distance_to(point) < center.distance_to(rid_closes_point[rid]):
				rid_closes_point[rid]= point

		for rid: RID in rid_map.keys():
			var rigidbody: RigidBody3D= rid_map[rid]
			var point: Vector3= rid_closes_point[rid]
			rigidbody.apply_impulse(force.damage.get_explosion_impulse_at(point), point - rigidbody.global_position)


func save_world(world_name: String= "", project_folder: bool= false):
	var base_path:= "user://"
	if project_folder:
		base_path= get_tree().current_scene.scene_file_path.get_base_dir() + "/"
	
	if world_name:
		if not DirAccess.open(base_path).dir_exists(world_name):
			DirAccess.open(base_path).make_dir(world_name)
		world_name+= "/"
		
	var save_file: FileAccess = FileAccess.open(base_path + world_name + SAVE_FILE_NAME, FileAccess.WRITE)
	for grid: BlockGrid in grids.get_children():
		var json_string = JSON.stringify(grid.serialize())
		save_file.store_line(json_string)
	save_file.close()


func load_world(world_name: String= "", project_folder: bool= false):
	var base_path:= "user://"
	if project_folder:
		base_path= get_tree().current_scene.scene_file_path.get_base_dir() + "/"

	var file_name: String= base_path
	
	if world_name:
		file_name+= world_name + "/"
	file_name+= SAVE_FILE_NAME
	if not FileAccess.file_exists(file_name):
		return

	var grid_data: Dictionary
	
	var save_file = FileAccess.open(file_name, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var grid: BlockGrid= BlockGrid.pre_deserialize(json.data, self)
		grid_data[grid]= json.data

	save_file.close()

	for grid: BlockGrid in grids.get_children():
		grid.deserialize(grid_data[grid])


func add_projectile(projectile: ProjectileObject):
	projectile.world= self
	projectiles.add_child(projectile)


func freeze_grids(b: bool):
	grid_freeze_state= b
	for grid: BlockGrid in grids.get_children():
		grid.freeze= b


func explosion(damage: Damage, obj: CollisionObject3D):
	var query:= PhysicsShapeQueryParameters3D.new()
	query.transform.origin= damage.position
	query.collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER
	var shape:= SphereShape3D.new()
	shape.radius= damage.radius
	query.shape= shape
	
	if obj:
		damage_object(obj, damage)
		damage= damage.duplicate()
		damage.shape_index= -1
		query.exclude= [obj.get_rid()]
	
	var result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query)
	if result:
		#prints("Explosion @%s with %d bodies" % [str(damage.position), result.size()])
		var rid_map: Dictionary
		for item: Dictionary in result:
			var collider: CollisionObject3D= item.collider
			if not rid_map.has(collider.get_rid()):
				rid_map[collider.get_rid()]= collider
				damage_object(collider, damage)
		
		var rest_result: Dictionary
		while true:
			rest_result= get_world_3d().direct_space_state.get_rest_info(query)
			if not rest_result: break
			#assert(rid_map.has(rest_result.rid))
			if rid_map.has(rest_result.rid):
				var collider: CollisionObject3D= rid_map[rest_result.rid]
				var point: Vector3= rest_result.point
				#prints(" Explosion contact point", point)
				
				var damage_at_point: float= damage.get_explosion_damage_at(point)
				# TODO investigate how point could be farther away from damage.position
				#  than damage.radius
				assert(damage_at_point >= 0, "radius %f vs distance %f" % [damage.radius, damage.position.distance_to(point)])
				
				if damage_at_point > 0:
					if collider is BlockGrid:
						pass
					elif collider is RigidBody3D:
						(collider as RigidBody3D).apply_impulse(damage.get_explosion_impulse_at(point), point - collider.global_position)
				
			query.exclude= query.exclude + [rest_result.rid]

	delayed_forces.append(DelayedExplosiveForce.new(damage))


func spawn_item(item: Item, pos: Vector3, rot: Vector3= Vector3.ZERO, count: int= 1, frozen: bool= false)-> WorldItemInstance:
	var item_instance: WorldItemInstance= WORLD_ITEM_SCENE.instantiate()
	item_instance.position= pos
	item_instance.rotation= rot
	item_instance.inv_item= InventoryItem.new(item, count)
	if item.has_dynamic_scale():
		item_instance.scale= Vector3.ONE * item.get_scale(count)
	item_instance.freeze= frozen
	
	var model: Node3D= item.model.instantiate()
	
	item_instance.add_child(model)

	items.add_child(item_instance)

	for collision_shape in model.find_children("*", "CollisionShape3D"):
		#collision_shape.owner= null
		collision_shape.reparent(item_instance)

	return item_instance


func spawn_inventory_item(inv_item: InventoryItem, pos: Vector3)-> WorldItemInstance:
	return spawn_item(inv_item.item, pos, Vector3.ZERO, inv_item.count)


func spawn_peripheral_entity(entity: PeripheralEntity, pos: Vector3, rot: Vector3):
	var entity_instance: PeripheralEntityInstance= entity.scene.instantiate()
	entity_instance.position= pos
	entity_instance.rotation= rot
	peripheral_entities.add_child(entity_instance)


func make_rope(from: Node3D, to: Node3D)-> Rope:
	var rope: Rope= GameData.scene_library.rope.instantiate()
	rope.start= from
	rope.end= to
	ropes.add_child(rope)
	return rope
	

func get_grid(id: int)-> BlockGrid:
	return grids.get_child(id)


func get_grid_id(grid: BlockGrid)-> int:
	return grids.get_children().find(grid)
