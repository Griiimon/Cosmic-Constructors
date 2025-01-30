class_name GameUI
extends CanvasLayer

@export var PROPERTY_VIEWER_SCENE: PackedScene

@onready var temporary_info_label: Label = %"Temporary Info Label"
@onready var temporary_info_label_cooldown: Timer = %"Temporary Info Label Cooldown"

@onready var jetpack_button: Button = %"Jetpack Button"
@onready var dampeners_button: Button = %"Dampeners Button"
@onready var parking_brake_button: Button = %"Parking Brake Button"

@onready var velocity_label: Label = %"Velocity Label"
@onready var gravity_label: Label = %"Gravity Label"

@onready var hotbar: Hotbar = $Hotbar

@onready var input_legend_container: GridContainer = %"GridContainer Input Legend"
@onready var input_legend_margin_container: MarginContainer = %"MarginContainer Input Legend"

@onready var block_category_selection_panel: BlockCategorySelectionPanel = %"Block Category Selection Panel"
@onready var blueprint_scroll_panel: BlueprintScrollPanel = %"Blueprint Scroll Panel"

@onready var line_edit_popup: LineEditPopup = $"Line Edit Popup"


var property_viewer_panel: PropertyViewerPanel

var input_legend_toggled: bool= false:
	set(b):
		input_legend_toggled= b
		if not is_inside_tree(): return
		input_legend_margin_container.visible= b



func _ready():
	Global.ui= self

	SignalManager.block_property_changed.connect(on_block_property_changed)
	SignalManager.build_block_changed.connect(on_build_block_changed)
	
	SignalManager.toggle_jetpack.connect(func(b: bool): jetpack_button.disabled= not b)
	SignalManager.toggle_dampeners.connect(func(b: bool): dampeners_button.disabled= not b)
	SignalManager.toggle_parking_brake.connect(func(b: bool): parking_brake_button.disabled= not b)

	SignalManager.player_set_action_state.connect(on_player_action_state_changed)

	SignalManager.interact_with_block.connect(on_interact_with_block)
	SignalManager.hotkey_assigned.connect(on_hotkey_assigned)
	SignalManager.toggle_block_category_panel.connect(on_toggle_block_category_panel)
		
	temporary_info_label_cooldown.timeout.connect(func(): temporary_info_label.hide())
	block_category_selection_panel.category_selected.connect(on_block_category_selected)

	property_viewer_panel= PROPERTY_VIEWER_SCENE.instantiate()
	property_viewer_panel.hide()
	add_child(property_viewer_panel)


func _physics_process(_delta: float) -> void:
	var player: Player= Global.player
	if player:
		velocity_label.text= "%.1f m/s" % player.get_velocity().length()

	if Input.is_action_just_pressed("toggle_input_legend"):
		input_legend_toggled= not input_legend_toggled


func switch_hotbar(hotbar_layout: HotbarLayout):
	hotbar.switch_layout(hotbar_layout)


func open_blueprint_menu():
	blueprint_scroll_panel.open()


func open_line_edit_popup(title: String, callback: Callable):
	line_edit_popup.open(title, callback)


func on_block_property_changed(prop: BlockProperty):
	update_temporary_info_label(prop.get_as_text())


func on_build_block_changed(block: Block):
	update_temporary_info_label(block.get_display_name())


func on_player_action_state_changed(state: PlayerActionStateMachineState):
	Utils.free_children(input_legend_container)
	
	var input_mappings: Dictionary= state.input_mappings
	
	if input_mappings.is_empty():
		input_legend_margin_container.hide()
	else:
		for input_action: String in input_mappings.keys():
			var action_label: Label= Utils.add_label(input_legend_container, Utils.get_input_action_mapping(input_action))
			action_label.add_theme_stylebox_override("normal", GameData.style_library.thin_white_border)
		
			var desc: String= input_mappings[input_action]
			var desc_label: Label= Utils.add_label(input_legend_container, desc)
			desc_label.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT

		if input_legend_toggled:
			input_legend_margin_container.show()


func update_temporary_info_label(s: String):
	temporary_info_label.text= s
	temporary_info_label.show()
	temporary_info_label_cooldown.stop()
	temporary_info_label_cooldown.start()


func on_interact_with_block(grid_block: GridBlock, grid: BlockGrid, player: Player):
	property_viewer_panel.update(grid_block, grid, player)


func on_hotkey_assigned(assignment: BaseHotkeyAssignment, grid: BlockGrid):
	update_temporary_info_label(str("Hotkey ", assignment.key, " assigned to ", assignment.get_as_text(grid)))


func on_toggle_block_category_panel():
	block_category_selection_panel.visible= not block_category_selection_panel.visible


func on_block_category_selected(category: BlockCategory):
	SignalManager.selected_block_category.emit(category)
