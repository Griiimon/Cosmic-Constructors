class_name NamedResource
extends Resource

@export var name: String



func get_display_name()-> String:
	if not name:
		if not resource_path or not "/" in resource_path:
			var code: String= (get_script() as GDScript).source_code
			var line: String= code.split("\n", true, 1)[0]
			return line.replace("class_name ", "")
			
		return resource_path.rsplit("/", true, 1)[1].trim_suffix(".tres").capitalize()

	return name.capitalize()
