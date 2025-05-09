class_name GridBlock
extends BaseGridBlock

var block_definition: Block
var rotation: Vector3i
var block_node: Node3D
var name: String
var hitpoints: int
var collision_shape: CollisionShape3D



func _init(_block: Block, _local_pos: Vector3i, _rotation: Vector3i= Vector3i.ZERO):
	super(_local_pos)
	block_definition= _block
	rotation= _rotation
	hitpoints= block_definition.max_hitpoints


# returns overflow damage
func take_damage(damage: int, grid: BlockGrid, type: Damage.SourceType= Damage.SourceType.UNKNOWN)-> int:
	assert(hitpoints > 0)
	hitpoints-= damage
	if hitpoints <= 0:
		destroy(grid)
		match type:
			Damage.SourceType.GRINDER:
				if block_definition.grind_drop:
					var item: InventoryItem= block_definition.grind_drop.get_drop_inv_item()
					grid.world.spawn_inventory_item(item, grid.get_global_block_pos(local_pos))
		return abs(hitpoints)
	return 0


func absorb_damage(damage: int)-> int:
	return max(damage - hitpoints, 0)


func destroy(grid: BlockGrid):
	var block_instance: BlockInstance= get_block_instance()
	if block_instance:
		block_instance.on_destroy(grid, self)
	else:
		block_node.queue_free()
	grid.remove_block(self)


func get_grid_block()-> GridBlock:
	return self


func get_block_instance()-> BlockInstance:
	return block_node as BlockInstance


func get_block_definition()-> Block:
	return block_definition


func get_local_basis()-> Basis:
	return rotation_to_basis(rotation)


func get_local_block_rotation()-> Vector3i:
	return get_local_basis().get_euler() / deg_to_rad(90)


func get_global_basis(grid: BlockGrid)-> Basis:
	#FIXME this is wrong!?
	return get_local_basis() * grid.global_basis


func to_global(offset: Vector3i)-> Vector3i:
	var vec: Vector3= Vector3(offset) * get_local_basis().inverse() + Vector3(local_pos)
	return vec.round()


func get_name(grid: BlockGrid)-> String:
	if not name.is_empty():
		return name
	return grid.generate_block_name(self)


func get_mass()-> int:
	var type: Block= get_block_definition()
	if type.has_dynamic_mass():
		return get_block_instance().get_dynamic_mass(self)
	return get_block_definition().mass
	

static func rotation_to_basis(block_rotation: Vector3i)-> Basis:
	return Basis.from_euler(block_rotation * deg_to_rad(90))	
