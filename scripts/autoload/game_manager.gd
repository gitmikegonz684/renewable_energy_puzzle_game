extends Node

## Autoload singleton (see project.godot [autoload]). Owns:
##   - which level we're on
##   - all scene-to-scene navigation
##
## Centralizing navigation here so individual screens never need to know
## about each other's scene paths.

var level_roster: Array[LevelData] = [
	preload("res://data/levels/level_1.tres"),
	preload("res://data/levels/level_2.tres")
	# Add more levels here as they go
]

var current_level_index: int = 0


## Returns the LevelData for the currently active level index.
## Call GameManager.get_current_level() from your game.gd _ready() function.
func get_current_level() -> LevelData:
	return level_roster[current_level_index]


## Called by the Title Screen's "Play" button.
func new_game() -> void:
	go_to_level(0)


## Called by the Game scene once the active puzzle is solved.
func level_complete() -> void:
	var next_index = current_level_index + 1
	
	if next_index >= level_roster.size():
		# Game beaten! Reset for next time and return to title.
		current_level_index = 0 
		go_to_title()
	else:
		go_to_level(next_index)


## Jumps directly to a specific level by index and handles the scene load.
func go_to_level(index: int) -> void:
	if index < 0 or index >= level_roster.size():
		push_error("GameManager: Attempted to load an invalid level index: ", index)
		return
		
	current_level_index = index
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# --- UI Navigation ---

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func go_to_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")


func go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
