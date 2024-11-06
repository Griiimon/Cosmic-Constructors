class_name GridBlock
extends Resource

var block_definition: Block
var local_pos: Vector3i
var rotation: Vector3i
var block_instance: BlockInstance



func _init(_block: Block, _local_pos: Vector3i, _rotation: Vector3i= Vector3i.ZERO):
	local_pos= _local_pos
	block_definition= _block
	rotation= _rotation


func get_local_basis()-> Basis:
	return Basis.from_euler(rotation)


func get_global_basis(grid: BlockGrid)-> Basis:
	return get_local_basis() * grid.global_basis
