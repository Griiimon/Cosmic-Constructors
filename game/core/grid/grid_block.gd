class_name GridBlock
# TODO change to plain class, saving system wont use Resources
extends Resource

var block_definition: Block
var local_pos: Vector3i
var rotation: Vector3i
var block_node: Node3D
var hitpoints: int
var collision_shape: CollisionShape3D



func _init(_block: Block, _local_pos: Vector3i, _rotation: Vector3i= Vector3i.ZERO):
	local_pos= _local_pos
	block_definition= _block
	rotation= _rotation
	hitpoints= block_definition.max_hitpoints


# return true if destroyed
func take_damage(damage: int)-> bool:
	hitpoints-= damage
	if hitpoints <= 0:
		destroy()
		return true
	return false


func destroy():
	var block_instance: BlockInstance= get_block_instance()
	if block_instance:
		block_instance.on_destroy()
	else:
		block_node.queue_free()


func get_block_instance()-> BlockInstance:
	return block_node as BlockInstance


func get_local_basis()-> Basis:
	return Basis.from_euler(rotation * deg_to_rad(90))


func get_global_basis(grid: BlockGrid)-> Basis:
	#FIXME this is wrong!?
	return get_local_basis() * grid.global_basis
