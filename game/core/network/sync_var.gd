class_name SyncVar

const KEY_NAME= "n"
const KEY_TARGET_TYPE= "t"
const KEY_TARGET_DATA= "d"
const KEY_VALUE= "v"

var name: String
var target: BaseSyncVarTarget
var updated:= false
var cached_hash= null



func _init(_name: String):
	name= _name
	if NetworkManager.is_server:
		ServerManager.register_sync_var(self)

	
func update():
	updated= true


func synced():
	updated= false


func requires_sync()-> bool:
	return updated


func set_value(_value: Variant):
	update()


func get_value()-> Variant:
	assert(false, "Abstract method")
	return null
	

func serialize()-> Dictionary:
	var data: Dictionary
	data[KEY_NAME]= name
	data[KEY_TARGET_TYPE]= target.type
	data[KEY_TARGET_DATA]= target.serialize()
	data[KEY_VALUE]= get_value()

	return data


static func deserialize(data: Dictionary)-> SyncVar:
	# FIXME add support for other types
	var var_name: String= data[KEY_NAME]
	var result:= SyncVarFloat.new(var_name)
	match data[KEY_TARGET_TYPE]:
		BaseSyncVarTarget.Type.BLOCK:
			result.target= SyncVarTargetBlock.deserialize(data[KEY_TARGET_DATA])
	result.set_value(data[KEY_VALUE])
	return result


func get_hash()-> int:
	if not cached_hash:
		cached_hash= hash({"name": name, "data": target.serialize()})
	return cached_hash


func get_as_text()-> String:
	return "%s: %s ( %s )" % [ name, str(get_value()), target.get_as_text() ]
