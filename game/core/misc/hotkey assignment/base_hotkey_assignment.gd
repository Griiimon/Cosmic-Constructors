class_name BaseHotkeyAssignment

var key: int



func _init(_key: int):
	key= _key


func serialize()-> Dictionary:
	assert(false, "abstract function")
	return {}


func get_as_text(_grid: BlockGrid= null)-> String:
	return ""
