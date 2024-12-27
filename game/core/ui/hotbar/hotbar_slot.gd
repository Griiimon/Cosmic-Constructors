class_name HotbarSlot
extends PanelContainer

@onready var label: Label = $Label

var tween: Tween



func set_text(s: String):
	label.text= s


func select():
	if tween and tween.is_running():
		tween.kill()
	tween= create_tween()
	modulate= Color.LIGHT_GREEN
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
