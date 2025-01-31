class_name BlockCategorySelectionPanel
extends ScrollSelectionPanel

signal category_selected(category: BlockCategory)



func _ready() -> void:
	super()
	SignalManager.canceled_build_mode.connect(func(): hide())
	populate()


func populate():
	clear()
	
	var row: BlockCategorySelectionRow= add_row("All")
	row.toggled.connect(choose_category.bind(null))
		
	for category: BlockCategory in GameData.block_categories.keys():
		row= add_row(category.get_display_name())
		row.category= category
		row.toggled.connect(choose_category.bind(category))

	selected_row= 0


func choose_category(category: BlockCategory):
	category_selected.emit(category)
	close()
