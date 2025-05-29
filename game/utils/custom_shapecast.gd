class_name CustomShapeCast

const DEBUG_MODE= false

static var grid: BlockGrid
static var grid_block: GridBlock



static func pierce(shapecast: ShapeCast3D, filter: Callable):
	reset()
	
	if not shapecast.is_colliding(): return
	
	while shapecast.is_colliding():
		if not filter.call(shapecast):
			shapecast.clear_exceptions()
			return
	
		shapecast.add_exception_rid(shapecast.get_collider_rid(0))
		shapecast.force_shapecast_update()
	
	shapecast.clear_exceptions()
	return


static func pierce_blocks(shapecast: ShapeCast3D, filter: Callable, step_size: float= 0.1):
	reset()

	if not shapecast.is_colliding(): return

	var query:= PhysicsShapeQueryParameters3D.new()
	query.shape= shapecast.shape
	query.collide_with_bodies= shapecast.collide_with_bodies
	query.collide_with_areas= shapecast.collide_with_areas
	query.collision_mask= shapecast.collision_mask
	query.transform= shapecast.global_transform

	var space_state: PhysicsDirectSpaceState3D= shapecast.get_world_3d().direct_space_state
	var pos: Vector3= shapecast.global_position
	var dir: Vector3= shapecast.global_position.direction_to(shapecast.to_global(shapecast.target_position))
	
	for i in shapecast.target_position.length() / step_size:
		pos+= dir
		query.transform.origin= pos
		var result: Array[Dictionary]= space_state.intersect_shape(query)
		if result:
			for j in result.size():
				var single_result: Dictionary= result[j]
				var collider: CollisionObject3D= single_result.collider
				if collider is BlockGrid:
					grid= collider

					#var shape_trans: Transform3D= grid.shape_owner_get_transform(first_result.shape)
					#FIXME this is probably bad performance-wise, but cant make finding shapes via owner work
					var coll_children: Array[Node]= grid.find_children("", "CollisionShape3D", false, false)
					var shape_trans: Transform3D= coll_children[single_result.shape].global_transform
					
					var base_block: BaseGridBlock= grid.get_block_from_global_pos(shape_trans.origin)
					if not base_block:
						# TODO is this happening because of previously deleted shapes, or moving grids, or custom collision shapes?
						push_warning("Custom Shapecast: no grid block")
						continue

					grid_block= base_block.get_grid_block()

					if not filter.call():
						return
					reset()


	if DEBUG_MODE and grid_block:
		DebugBlockFrame.place_global(grid_block.get_block_instance().global_transform)


static func reset():
	grid= null
	grid_block= null
