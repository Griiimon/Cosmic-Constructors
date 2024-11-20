extends Node

const DEBUG_PANEL_SCENE= preload("res://game/global/debug panel/single_debug_panel.tscn")

var enabled:= false
var panels: Dictionary



func send(object: Node3D, key: String, value):
	var panel: SingleDebugPanel
	if not panels.has(object):
		panel= DEBUG_PANEL_SCENE.instantiate()
		add_child(panel)
		panels[object]= panel
		panel.visible= enabled
	else:
		panel= panels[object]
	
	panel.set_labels(key, str(value))


func _process(_delta: float):
	if not enabled: return
	
	var camera: Camera3D= get_viewport().get_camera_3d()

	for obj in panels.keys().duplicate():
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			panels[obj].queue_free()
			panels.erase(obj)
			continue

		var panel: SingleDebugPanel= panels[obj]
		if not camera.is_position_behind(obj.global_position):
			panel.position= camera.unproject_position(obj.global_position)


func toggle():
	enabled= not enabled
	for panel: SingleDebugPanel in panels.values():
		panel.visible= enabled
