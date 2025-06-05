class_name World
extends Node3D

signal finished_loading

const SAVE_FILE_NAME= "world.json"
const WORLD_ITEM_SCENE= preload("res://game/core/world/world item/world_item_instance.tscn")

class DelayedExplosiveForce:
	var damage_instance: DamageInstance
	var countdown: int
	
	func _init(_damage_instance: DamageInstance):
		damage_instance= _damage_instance.copy()
		countdown= 2


var grids: Node
var projectiles: Node
var items: Node
var peripheral_entities: Node
var ropes: Node
var objects: Node

static var next_grid_id: int= 0
var lookup_id_to_grid: Dictionary
#var lookup_grid_to_id: Dictionary

var grid_freeze_state:= false

var delayed_forces: Array[DelayedExplosiveForce]

var is_loading:= false

var factions: Array[Faction]
var default_faction: Faction



func _ready() -> void:
	grids= generate_sub_node("Grids")
	projectiles= generate_sub_node("Projectiles")
	items= generate_sub_node("Items")
	peripheral_entities= generate_sub_node("Peripheral Entities")
	ropes= generate_sub_node("Ropes")
	objects= generate_sub_node("Objects")


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


func add_grid(pos: Vector3, rot: Vector3= Vector3.ZERO, block_size: float= 1.0, _faction: Faction= null)-> BlockGrid:
	var grid:= BlockGrid.new(block_size)
	assign_grid_id(grid)
	init_grid(grid, pos, rot)
	grid.faction= _faction
	return grid


func assign_grid_id(grid: BlockGrid, new_id: bool= true, custom_id: int= -1, reassign: bool= true):
	var new_grid_id: int
	if new_id:
		new_grid_id= next_grid_id
		next_grid_id+= 1
	else:
		if reassign:
			assert(not lookup_id_to_grid.has(custom_id))
			assert(grid.id != -1)
			assert(grid.id_pending)
			
			lookup_id_to_grid.erase(grid.id)
		new_grid_id= custom_id
	
	grid.id= new_grid_id
	lookup_id_to_grid[new_grid_id]= grid


func init_grid(grid: BlockGrid, pos: Vector3, rot: Vector3):
	grid.position= pos
	grid.rotation= rot
	grid.world= self
	grid.current_gravity= PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR) * PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	grids.add_child(grid)
	
	if not grid.freeze:
		grid.freeze= grid_freeze_state
	
	if NetworkManager.is_client:
		grid.freeze= true


func remove_grid(grid: BlockGrid):
	grid.removed.emit()
	lookup_id_to_grid.erase(grid.id)
	#lookup_grid_to_id.erase(grid)
	grids.remove_child(grid)
	grid.queue_free()


# not used
func add_custom_grid(grid: BlockGrid, pos: Vector3, rot: Vector3= Vector3.ZERO)-> BlockGrid:
	init_grid(grid, pos, rot)
	return grid


func damage_point(damage_instance: DamageInstance, obj: CollisionObject3D= null):
	if damage_instance.damage.is_explosion():
		explosion(damage_instance, obj)
		#Effects.spawn_explosion(damage.position, damage.radius)
		Effects.create(ExplosionEffect.new(damage_instance.position, damage_instance.damage.radius))
	else:
		damage_object(obj, damage_instance)


func damage_object(obj: CollisionObject3D, damage_instance: DamageInstance):
	var collision_shapes: Array[CollisionShape3D]
	if damage_instance.damage.is_explosion():
		var query:= PhysicsShapeQueryParameters3D.new()
		query.transform.origin= damage_instance.position
		query.shape= SphereShape3D.new()
		query.shape.radius= damage_instance.damage.radius
		
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
		 	return a.global_position.distance_squared_to(damage_instance.position) >\
				b.global_position.distance_squared_to(damage_instance.position))

		RaycastHelper.hit_from_inside= false
		RaycastHelper.hit_back_faces= false
		RaycastHelper.collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID

		for coll_shape in collision_shapes:
			var ray_origin: Vector3= coll_shape.global_position
			var ray_target: Vector3= damage_instance.position
			var result: RaycastHelper.PierceResult= RaycastHelper.pierce(ray_origin, ray_target)
			if not result.items.is_empty():
				result.items.reverse()
				
				var total_damage: int= damage_instance.damage.amount
				
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
					deal_damage_via_collision_shape(damage_instance, coll_shape, total_damage)

	var shape_index: int= damage_instance.shape_index if damage_instance.shape_index > -1 else 0
	var impact_coll_shape: CollisionShape3D= obj.shape_owner_get_owner(obj.shape_find_owner(shape_index))
	deal_damage_via_collision_shape(damage_instance, impact_coll_shape)


func deal_damage_via_collision_shape(damage_instance: DamageInstance, coll_shape: CollisionShape3D, custom_amount: int = -1):
	var damage_component: DamageComponent= DamageComponent.get_component(coll_shape.get_parent())
	if damage_component:
		damage_instance.override_amount= custom_amount
		damage_component.take_damage(damage_instance, coll_shape)


func apply_delayed_explosive_force(force: DelayedExplosiveForce):
	var center: Vector3= force.damage_instance.position

	var query:= PhysicsShapeQueryParameters3D.new()
	query.transform.origin= center
	query.collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID
	var shape:= SphereShape3D.new()
	shape.radius= force.damage_instance.damage.radius
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
			rigidbody.apply_impulse(force.damage_instance.get_explosion_impulse_at(point), point - rigidbody.global_position)


func save_world(world_name: String= "", project_folder: bool= false):
	assert(not NetworkManager.is_client)
	
	var base_path:= "user://"
	if project_folder:
		base_path= get_tree().current_scene.scene_file_path.get_base_dir() + "/"
	
	if world_name:
		if not DirAccess.open(base_path).dir_exists(world_name):
			DirAccess.open(base_path).make_dir(world_name)
		world_name+= "/"
	
	var file_path: String= base_path + world_name + SAVE_FILE_NAME
	var save_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	assert(FileAccess.get_open_error() == OK)

	var world_data:= {}
	world_data["grids"]= []
	world_data["factions"]= []
	world_data["players"]= []
	world_data["items"]= []
	
	for grid: BlockGrid in grids.get_children():
		world_data["grids"].append(grid.serialize())

	for faction in factions:
		world_data["factions"].append(faction.serialize())

	if NetworkManager.is_single_player:
		world_data["players"].append(Global.player.serialize())
	else:
		world_data["players"]= await ServerManager.serialize_players()

	for item: WorldItemInstance in items.get_children():
		world_data["items"].append(item.serialize())

	var json_string = JSON.stringify(world_data)
	assert(not json_string.is_empty())
	
	save_file.store_line(json_string)

	save_file.close()
	
	assert(not FileAccess.get_file_as_string(file_path).is_empty())


func load_world_from_file(world_name: String= "", project_folder: bool= false):
	var base_path:= "user://"
	if project_folder:
		base_path= get_tree().current_scene.scene_file_path.get_base_dir() + "/"

	var file_name: String= base_path
	
	if world_name:
		file_name+= world_name + "/"
	file_name+= SAVE_FILE_NAME
	if not FileAccess.file_exists(file_name):
		return

	prints("Loading world", file_name)

	#var save_file = FileAccess.open(file_name, FileAccess.READ)
	
	var json = JSON.new()

	var file_text: String= FileAccess.get_file_as_string(file_name)
	#save_file.close()

	var parse_result = json.parse(file_text)
	if not parse_result == OK:
		print(file_text)
		push_error("JSON Parse Error: ", json.get_error_message(), " in ", file_text, " at line ", json.get_error_line())
		breakpoint
		

	load_world(json.data)


func load_world(world_data: Dictionary):
	is_loading= true
	
	var world_grid_data: Dictionary

	for grid_data: Dictionary in world_data["grids"]:
		var grid: BlockGrid= BlockGrid.pre_deserialize(grid_data, self)
		world_grid_data[grid]= grid_data
		if NetworkManager.is_client:
			grid.freeze= true

	for grid: BlockGrid in grids.get_children():
		grid.deserialize(world_grid_data[grid])

	if world_data.has("factions"):
		for faction_data: Dictionary in world_data["factions"]:
			factions.append(Faction.deserialize(faction_data))

	if not world_data["players"].is_empty():
		var player_data_arr: Array[Dictionary]
		player_data_arr.assign(world_data["players"])
		if NetworkManager.is_single_player:
			Global.player.deserialize(player_data_arr[0])
		else:
			ServerManager.set_player_data(player_data_arr)

	if world_data.has("items"):
		for item_data: Dictionary in world_data["items"]:
			spawn_serialized_item(item_data)

	# to ensure everything was initialized properly and deferred calls have been handled
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame

	is_loading= false
	finished_loading.emit()


func add_projectile(projectile: ProjectileObject):
	projectile.world= self
	projectiles.add_child(projectile)


func freeze_grids(b: bool):
	#grid_freeze_state= b
	for grid: BlockGrid in grids.get_children():
		if not grid.is_anchored:
			grid.freeze= b


func explosion(damage_instance: DamageInstance, obj: CollisionObject3D):
	var query:= PhysicsShapeQueryParameters3D.new()
	query.transform.origin= damage_instance.position
	query.collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID
	var shape:= SphereShape3D.new()
	shape.radius= damage_instance.damage.radius
	query.shape= shape
	
	if obj:
		damage_object(obj, damage_instance)
		damage_instance= damage_instance.copy()
		damage_instance.shape_index= -1
		query.exclude= [obj.get_rid()]
	
	var result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query)
	if result:
		#prints("Explosion @%s with %d bodies" % [str(damage.position), result.size()])
		var rid_map: Dictionary
		for item: Dictionary in result:
			var collider: CollisionObject3D= item.collider
			if not rid_map.has(collider.get_rid()):
				rid_map[collider.get_rid()]= collider
				damage_object(collider, damage_instance)
		
		var rest_result: Dictionary
		while true:
			rest_result= get_world_3d().direct_space_state.get_rest_info(query)
			if not rest_result: break
			#assert(rid_map.has(rest_result.rid))
			if rid_map.has(rest_result.rid):
				var collider: CollisionObject3D= rid_map[rest_result.rid]
				var point: Vector3= rest_result.point
				#prints(" Explosion contact point", point)
				
				var damage_at_point: float= damage_instance.get_explosion_damage_at(point)
				# TODO investigate how point could be farther away from damage.position
				#  than damage.radius
				assert(damage_at_point >= 0, "radius %f vs distance %f" % [damage_instance.damage.radius, damage_instance.position.distance_to(point)])
				
				if damage_at_point > 0:
					if collider is BlockGrid:
						pass
					elif collider is RigidBody3D:
						(collider as RigidBody3D).apply_impulse(damage_instance.damage.get_explosion_impulse_at(point), point - collider.global_position)
				
			query.exclude= query.exclude + [rest_result.rid]

	delayed_forces.append(DelayedExplosiveForce.new(damage_instance))


func spawn_item(item: Item, pos: Vector3, rot: Vector3= Vector3.ZERO, count: int= 1, frozen: bool= false)-> WorldItemInstance:
	var item_instance: WorldItemInstance= WORLD_ITEM_SCENE.instantiate()
	item_instance.position= pos
	item_instance.rotation= rot
	item_instance.inv_item= InventoryItem.new(item, count)
	if item.has_dynamic_scale():
		item_instance.scale= Vector3.ONE * item.get_scale(count)
	item_instance.freeze= frozen
	if item.collides_with_player():
		item_instance.collision_mask+= CollisionLayers.PLAYER
	
	var model: Node3D= item.model.instantiate()
	
	item_instance.add_child(model)

	items.add_child(item_instance)


	for collision_shape in model.find_children("*", "CollisionShape3D"):
		#collision_shape.owner= null
		if frozen:
			collision_shape.queue_free()
		else:
			collision_shape.reparent(item_instance)

	return item_instance


func spawn_inventory_item(inv_item: InventoryItem, pos: Vector3, rot: Vector3= Vector3.ZERO, frozen: bool= false)-> WorldItemInstance:
	return spawn_item(inv_item.item, pos, rot, inv_item.count, frozen)


func spawn_serialized_item(data: Dictionary):
	var inv_item: InventoryItem= InventoryItem.deserialize(data["inv_item"])
	var pos: Vector3= Utils.get_key_or_default(data, "pos", Vector3.ZERO, "Vector3")
	var rot: Vector3= Utils.get_key_or_default(data, "rot", Vector3.ZERO, "Vector3")
	var item_inst: WorldItemInstance= spawn_inventory_item(inv_item, pos, rot)

	var linear_velocity: Vector3= Utils.get_key_or_default(data, "vel", Vector3.ZERO, "Vector3")
	var angular_velocity: Vector3= Utils.get_key_or_default(data, "ang_vel", Vector3.ZERO, "Vector3")

	item_inst.linear_velocity= linear_velocity
	item_inst.angular_velocity= angular_velocity


func spawn_object(scene: PackedScene, pos: Vector3, rot: Vector3= Vector3.ZERO, velocity: Vector3= Vector3.ZERO, id: int= -1)-> ObjectEntity:
	assert(scene)
	var obj: ObjectEntity= scene.instantiate()
	obj.position= pos
	obj.rotation= rot
	obj.linear_velocity= velocity
	objects.add_child(obj)
	if id > -1:
		obj.id= id

	if NetworkManager.is_server:
		ServerManager.broadcast_sync_event(EventSyncState.Type.SPAWN_OBJECT, [scene.resource_path, obj.id, pos, rot, velocity])
	elif NetworkManager.is_client:
		obj.hide()
		obj.freeze= true

	return obj


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


func add_faction(faction: Faction):
	faction.id= factions.size()
	if faction.is_default:
		assert(not default_faction)
		default_faction= faction
	factions.append(faction)


func has_grid(id: int)-> bool:
	return lookup_id_to_grid.has(id)


func get_grid(id: int)-> BlockGrid:
	return lookup_id_to_grid[id]


func get_grids()-> Array[BlockGrid]:
	var result: Array[BlockGrid]
	result.assign(grids.get_children())
	return result


func get_object(id: int)-> ObjectEntity:
	for obj in get_objects():
		if obj.id == id:
			return obj
	return null


func get_objects()-> Array[ObjectEntity]:
	var result: Array[ObjectEntity]
	result.assign(objects.get_children())
	return result


func get_faction(id: int)-> Faction:
	if id >= factions.size():
		return null
	return factions[id]


func is_point_under_water(point: Vector3)-> bool:
	var terrain: BaseTerrainComponent= Global.terrain
	if terrain:
		return terrain.is_point_under_water(point)
	return false
		
