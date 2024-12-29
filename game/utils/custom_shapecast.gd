class_name CustomShapeCast

const DEBUG_MODE= true

static var grid: BlockGrid
static var grid_block: BaseGridBlock



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
	#var dir: Vector3= (shapecast.target_position * shapecast.global_transform.inverse()).normalized()
	var dir: Vector3= shapecast.global_position.direction_to(shapecast.to_global(shapecast.target_position))
	
	for i in shapecast.target_position.length() / step_size:
		pos+= dir
		query.transform.origin= pos
		var result: Array[Dictionary]= space_state.intersect_shape(query)
		if result:
			var first_result: Dictionary= result[0]
			var collider: CollisionObject3D= first_result.collider
			if collider is BlockGrid:
				grid= collider
				var shape_trans: Transform3D= grid.shape_owner_get_transform(first_result.shape)
				# TODO following line may fail to produce correct result?
				#		.. with multi blocks at least? 
				grid_block= grid.get_block_local(round(shape_trans.origin))
				var tmp: GridBlock= grid_block
				if not filter.call():
					break
				reset()


	if DEBUG_MODE and grid_block:
		DebugBlockFrame.place_global(grid_block.get_block_instance().global_transform)
		

static func reset():
	grid= null
	grid_block= null
