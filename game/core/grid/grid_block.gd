class_name GridBlock
extends Resource

var block: Block
var local_pos: Vector3i
var rotation: Vector3i



func _init(_block: Block, _local_pos: Vector3i):
	local_pos= _local_pos
	block= _block
