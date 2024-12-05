class_name CustomShapeCast

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


static func reset():
	grid= null
	grid_block= null
