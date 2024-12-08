class_name MyTerrain
extends VoxelLodTerrain


@export var world: World
@export var terrain_properties: TerrainProperties



func _ready() -> void:
	await get_parent().ready
	if not world:
		world= Global.game.world
	assert(world != null)


func mine(local_pos: Vector3i, radius: float, material_spawn_pos: Vector3, item_impulse: Vector3):
	var new_resources: Dictionary= VoxelUtils.mined(self, local_pos, radius)

	var collected_resources: Dictionary
	
	for key in new_resources.keys():
		if not collected_resources.has(key):
			collected_resources[key]= 0.0
		collected_resources[key]+= new_resources[key]
		var raw_item: RawItem= terrain_properties.types[key].raw_material
		var item_instance: WorldItemInstance= world.spawn_item(raw_item, material_spawn_pos)
		item_instance.linear_velocity= item_impulse
	#DebugHud.send("Gold", collected_resources[1] if collected_resources.has(1) else 0.0)	
	DebugHud.send("Ress", collected_resources)
