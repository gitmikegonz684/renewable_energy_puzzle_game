extends Node

## Autoload singleton (see project.godot [autoload]). Owns:
##   - which level we're on
##   - the currently loaded LevelData
##   - all scene-to-scene navigation
##
## Centralizing navigation here means individual screens never need to know
## about each other's scene paths.

## Ordered list of levels. To add a level: drop a new LevelData .tres into
## data/levels/ and add its path here. Nothing else needs to change.
const LEVEL_PATHS: Array[String] = [
	"res://data/levels/level_1.tres",
	"res://data/levels/level_2.tres",
]

var current_level_index: int = 0
var current_level_data: LevelData = null


## Called by the Title Screen's "Play" button. A brand-new game
## always starts at level 1 and never visits the Level Select screen.
func new_game() -> void:
	current_level_index = 0
	_load_current_level_data()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


## Called by the Game scene once the active puzzle is solved.
func level_complete() -> void:
	current_level_index += 1
	if current_level_index < LEVEL_PATHS.size():
		_load_current_level_data()
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		# Ran out of levels. There's no "you beat the game" screen yet -
		# return to the title screen as a safe default.
		go_to_title()


## Jumps directly to a specific level by index. Used by the (stubbed)
## Level Select screen for a future "Continue Game" flow.
func go_to_level(index: int) -> void:
	current_level_index = index
	_load_current_level_data()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func go_to_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")


func go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _load_current_level_data() -> void:
	var path: String = LEVEL_PATHS[current_level_index]
	current_level_data = load(path) as LevelData
