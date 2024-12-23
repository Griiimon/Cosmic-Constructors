class_name BaseGridBlock

var local_pos: Vector3i



func _init(_local_pos: Vector3i):
	local_pos= _local_pos


# returns true if destroyed
func take_damage(_damage: int, _grid: BlockGrid)-> int:
	assert(false, "Abstract class")
	return 0


func absorb_damage(_damage: int)-> int:
	assert(false, "Abstract class")
	return 0


func destroy(_grid: BlockGrid):
	assert(false, "Abstract class")
	pass


func get_block_instance()-> BlockInstance:
	assert(false, "Abstract class")
	return null


func get_block_definition()-> Block:
	assert(false, "Abstract class")
	return null
	

func get_local_basis()-> Basis:
	assert(false, "Abstract class")
	return Basis.IDENTITY


func get_global_basis(_grid: BlockGrid)-> Basis:
	assert(false, "Abstract class")
	return Basis.IDENTITY


func to_global(offset: Vector3i)-> Vector3i:
	assert(false, "Abstract class")
	return Vector3i.ZERO
