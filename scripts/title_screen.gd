extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "Renewable Energy Puzzle Game"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var play_button := Button.new()
	play_button.text = "Play"
	play_button.custom_minimum_size = Vector2(220, 50)
	play_button.pressed.connect(_on_play_pressed)
	vbox.add_child(play_button)


func _on_play_pressed() -> void:
	GameManager.new_game()


func _on_settings_pressed() -> void:
	GameManager.go_to_settings()
