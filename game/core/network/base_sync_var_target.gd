class_name BaseSyncVarTarget

enum Type { BLOCK }

var type: Type



func _init(_type: Type):
	type= _type 


func serialize()-> Dictionary:
	assert(false, "Abstract method")
	return {}


func get_as_text()-> String:
	assert(false, "Abstract method")
	return ""
