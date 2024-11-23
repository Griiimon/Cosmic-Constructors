extends RayCast3D

@export var scroll_steps: float= 0.1


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if target_position.length() < 2: return
				target_position-= target_position.normalized() * scroll_steps
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_position+= target_position.normalized() * scroll_steps
