class_name BaseGridBlock

var local_pos: Vector3i



func _init(_local_pos: Vector3i):
	local_pos= _local_pos


# returns true if destroyed
func take_damage(damage: int, grid: BlockGrid)-> bool:
	assert(false, "Abstract class")
	return false


func destroy(grid: BlockGrid):
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


func get_global_basis(grid: BlockGrid)-> Basis:
	assert(false, "Abstract class")
	return Basis.IDENTITY