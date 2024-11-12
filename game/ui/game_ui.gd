class_name GameUI
extends CanvasLayer

@onready var block_prop_label: Label = %"Block Prop Label"
@onready var block_prop_label_cooldown: Timer = %"Block Prop Label Cooldown"



func _ready():
	SignalManager.block_property_changed.connect(update_block_prop_label)
	block_prop_label_cooldown.timeout.connect(func(): block_prop_label.hide())


func update_block_prop_label(block_prop: BlockProperty):
	block_prop_label.text= block_prop.get_as_text()
	block_prop_label.show()
	block_prop_label_cooldown.stop()
	block_prop_label_cooldown.start()
