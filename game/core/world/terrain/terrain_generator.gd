class_name TerrainGenerator
extends Resource

static var query: PhysicsShapeQueryParameters3D



func get_height(x: float, z: float)-> float:
	return 0


static func activate_chunk(pos: Vector3, size: Vector3):
	if not query:
		query= PhysicsShapeQueryParameters3D.new()
		query.collide_with_bodies= false
		query.collide_with_areas= true
		query.collision_mask= CollisionLayers.LOD_ACTIVATED

	var scene_tree: SceneTree= Global.get_tree()
	await scene_tree.physics_frame
	
	query.transform.origin= pos
	var shape:= BoxShape3D.new()
	shape.size= size
	query.shape= shape
	
	#prints("Lod Activation Query", pos, size)

	var space_state: PhysicsDirectSpaceState3D= (scene_tree.current_scene as Node3D).get_world_3d().direct_space_state
	var result: Array[Dictionary]= space_state.intersect_shape(query)
	for item: Dictionary in result:
		var lod_activated: LodActivated= item.collider
		assert(lod_activated)
		lod_activated.activate()
