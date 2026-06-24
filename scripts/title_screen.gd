extends Control	

func _on_settings_pressed() -> void:
	GameManager.go_to_settings()

func _on_play_button_pressed() -> void:
	GameManager.new_game()
