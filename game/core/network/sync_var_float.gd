class_name SyncVarFloat
extends SyncVar

var f: float



func set_value(value: Variant):
	f= value
	super(value)


func get_value()-> Variant:
	return f
