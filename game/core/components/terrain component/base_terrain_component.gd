class_name BaseTerrainComponent
extends Node

class VoxelDetail:
	var pos: Vector3i
	var terrain_block: BaseVoxelTerrainBlock
	
	func _init(_pos: Vector3i, _terrain_block: BaseVoxelTerrainBlock):
		pos= _pos
		terrain_block= _terrain_block



const NODE_NAME= "Terrain Component"

@export var world: World
@export var terrain_properties: TerrainProperties
@export var height_map_provider: HeightMapProvider

@onready var terrain_node: Node3D= get_parent()



func _init():
	Global.terrain= self
	#set_process(false)


func _ready() -> void:
	assert(terrain_node.collision_layer == CollisionLayers.TERRAIN)

	await get_parent().ready
	if not world:
		world= Global.game.world
	assert(world != null, "Auto-acquire World failed, set manually")

	name= NODE_NAME


func mine(local_pos: Vector3, radius: float, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
	return {}


func grind(local_pos: Vector3, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO):
	pass


func save():
	pass


func has_lod_activation()-> bool:
	return terrain_node is VoxelNode


func is_point_under_water(point: Vector3)-> bool:
	return false


static func get_terrain(parent_node: Node3D)-> BaseTerrainComponent:
	var terrain: BaseTerrainComponent= parent_node.get_node_or_null(NODE_NAME)
	assert(terrain != null, "Node %s doesn't have a child node %s of type BaseTerrainComponent" % [ parent_node.name, NODE_NAME ])
	return terrain
