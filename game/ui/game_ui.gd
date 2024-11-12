class_name GameUI
extends CanvasLayer

@onready var temporary_info_label: Label = %"Temporary Info Label"
@onready var temporary_info_label_cooldown: Timer = %"Temporary Info Label Cooldown"



func _ready():
	SignalManager.block_property_changed.connect(on_block_property_changed)
	SignalManager.build_block_changed.connect(on_build_block_changed)
	temporary_info_label_cooldown.timeout.connect(func(): temporary_info_label.hide())


func on_block_property_changed(prop: BlockProperty):
	update_temporary_info_label(prop.get_as_text())


func on_build_block_changed(block: Block):
	update_temporary_info_label(block.get_display_name())


func update_temporary_info_label(s: String):
	temporary_info_label.text= s
	temporary_info_label.show()
	temporary_info_label_cooldown.stop()
	temporary_info_label_cooldown.start()
