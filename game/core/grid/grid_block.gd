class_name GridBlock
extends BaseGridBlock

var block_definition: Block
var rotation: Vector3i
var block_node: Node3D
var hitpoints: int
var collision_shape: CollisionShape3D



func _init(_block: Block, _local_pos: Vector3i, _rotation: Vector3i= Vector3i.ZERO):
	super(_local_pos)
	block_definition= _block
	rotation= _rotation
	hitpoints= block_definition.max_hitpoints


# returns overflow damage
func take_damage(damage: int, grid: BlockGrid)-> int:
	hitpoints-= damage
	if hitpoints <= 0:
		destroy(grid)
		return abs(hitpoints)
	return 0


func absorb_damage(damage: int)-> int:
	return max(damage - hitpoints, 0)


func destroy(grid: BlockGrid):
	var block_instance: BlockInstance= get_block_instance()
	if block_instance:
		block_instance.on_destroy()
	else:
		block_node.queue_free()
	grid.remove_block(self)


func get_block_instance()-> BlockInstance:
	return block_node as BlockInstance


func get_block_definition()-> Block:
	return block_definition


func get_local_basis()-> Basis:
	return rotation_to_basis(rotation)


func get_global_basis(grid: BlockGrid)-> Basis:
	#FIXME this is wrong!?
	return get_local_basis() * grid.global_basis


func to_global(local_pos: Vector3i, offset: Vector3i)-> Vector3i:
	return (Vector3(offset) * get_local_basis() + Vector3(local_pos)).round()


static func rotation_to_basis(block_rotation: Vector3i)-> Basis:
	return Basis.from_euler(block_rotation * deg_to_rad(90))	
