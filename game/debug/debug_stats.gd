extends Node

var stored_values: Dictionary



func log_max(key: String, val: Variant):
	if not stored_values.has(key):
		stored_values[key]= val
	elif val > stored_values[key]:
		stored_values[key]= val


func get_value(key: String)-> Variant:
	if not stored_values.has(key):
		return null
	return stored_values[key]
