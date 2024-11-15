class_name World
extends Node3D

const SAVE_FILE_NAME= "world.json"

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
	if not is_zero_approx(damage.radius):
		var query:= PhysicsShapeQueryParameters3D.new()
		query.transform.origin= damage.position
		query.shape= SphereShape3D.new()
		query.shape.radius= damage.radius
		
		var shape_result: Array[Dictionary]= get_world_3d().direct_space_state.intersect_shape(query, 100)
		if shape_result:
			for item in shape_result:
				var coll_shape: CollisionShape3D= item.collider.shape_owner_get_owner(item.collider.shape_find_owner(item.shape))
				collision_shapes.append(coll_shape)
				prints("Damage object %s impact @%s shape #%d @%s" % [str(item.collider.name), str(damage.position), item.shape, str(coll_shape.global_position)])
				#DebugMesh.create(coll_shape.global_position + Vector3.UP, 0.3)
	
		print("Damage %d shapes" % collision_shapes.size())
		
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
				#assert(result.items[-1].object == obj)
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
								var block: GridBlock= grid.get_block_local(block_pos)
								total_damage= block.absorb_damage(total_damage)
				
							prints(" Total damage %d after piercing through %d blocks" %[total_damage, pierced_blocks.size()])

						else:
							var damage_component: DamageComponent= DamageComponent.get_component(collider)
							total_damage= damage_component.absorb_damage(total_damage, pierce_item.coll_shape)
				
				prints("Total damage %d @%s after piercing through %d colliders" %[total_damage, str(coll_shape.global_position), result.items.size()])
				
				if total_damage > 0:
					deal_damage_via_collision_shape(damage, coll_shape, total_damage)

	var center_coll_shape: CollisionShape3D= obj.shape_owner_get_owner(obj.shape_find_owner(damage.shape_index))
	deal_damage_via_collision_shape(damage, center_coll_shape)


func deal_damage_via_collision_shape(orig_damage: Damage, coll_shape: CollisionShape3D, custom_amount: int = -1):
	var damage_component: DamageComponent= DamageComponent.get_component(coll_shape.get_parent())
	if damage_component:
		var final_damage: Damage= orig_damage.duplicate()
		if custom_amount > -1:
			final_damage.amount= custom_amount
		damage_component.take_damage(final_damage, coll_shape)


func save_world(world_name: String= "", project_folder: bool= false):
	var base_path:= "user://"
	if project_folder:
		base_path= get_tree().current_scene.scene_file_path
	
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
		base_path= get_tree().current_scene.scene_file_path

	var file_name: String= base_path
	
	if world_name:
		file_name+= world_name + "/"
	file_name+= SAVE_FILE_NAME
	if not FileAccess.file_exists(file_name):
		return

	var save_file = FileAccess.open(file_name, FileAccess.READ)
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
	save_file.close()


func add_projectile(projectile: ProjectileObject):
	projectile.world= self
	projectiles.add_child(projectile)


func freeze_grids(b: bool):
	grid_freeze_state= b
	for grid: BlockGrid in grids.get_children():
		grid.freeze= b
