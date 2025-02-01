class_name BlueprintScrollPanel
extends ScrollSelectionPanel


func populate():
	clear()
	
	var dir:= DirAccess.open(GameData.game_settings.misc_settings.blueprint_folder)
	for sub_dir in dir.get_directories():
		var row: ScrollSelectionRow= add_row(sub_dir)
		row.toggled.connect(on_row_toggled.bind(sub_dir))

	if not rows.is_empty():
		selected_row= 0


func on_row_toggled(dir_name: String):
	SignalManager.blueprint_selected.emit(dir_name)
	close()
