class_name BaseHotkeyAssignment

var key: int



func _init(_key: int):
	key= _key


func serialize()-> Dictionary:
	assert(false, "abstract function")
	return {}


func get_as_text(grid: BlockGrid= null)-> String:
	return ""
