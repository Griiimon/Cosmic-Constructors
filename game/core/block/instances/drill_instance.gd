extends BlockInstanceOnOff

@export var rotation_speed: float= 5.0
@export var drill_head: MeshInstance3D
@export var terrain_shapecast: ShapeCast3D

@onready var item_container: ItemContainer = $"Item Container"

var cooldown: Timer



func _ready() -> void:
	super()
	default_interaction_property= active

	cooldown= Timer.new()
	cooldown.one_shot= true
	cooldown.wait_time= 1.0
	add_child(cooldown)


func _process(delta: float) -> void:
	if active.is_true():
		drill_head.rotate_z(rotation_speed * delta)


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if active.is_true():
		if cooldown.is_stopped():
			if terrain_shapecast.is_colliding():
				var terrain: MyTerrain= MyTerrain.get_terrain(terrain_shapecast.get_collider(0))
				var local_pos: Vector3= terrain.terrain_node.to_local(terrain_shapecast.get_collision_point(0))
				var radius: float= (terrain_shapecast.shape as SphereShape3D).radius
				var resources: Dictionary= terrain.mine(local_pos, radius, global_position)
				
				item_container.inventory.add_from_dict(resources)
				
			cooldown.start()
