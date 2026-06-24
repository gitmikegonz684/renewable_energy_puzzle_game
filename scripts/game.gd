extends Control

# --- 1. INJECT THE VISUAL NODES ---
@export var tile_map_layer: TileMapLayer
@export var level_label: Label
@export var art_display: TextureRect
@export var grid_area: SubViewportContainer
@export var sub_viewport: SubViewport
@export var camera: Camera2D
@export var level_data: LevelData

@onready var bg_animation_player: AnimationPlayer = $GameplayScreen/AnimationPlayer

var solved: bool = false

func _ready() -> void:
	# OVERRIDE the editor's static data with the dynamic data from the Manager
	level_data = GameManager.get_current_level()
	
	# Populate dynamic data directly
	level_label.text = "Level %d" % level_data.level_id
	
	# Trigger the specific animation for this level
	_play_level_background()
	
	_populate_tilemap()
	
func _play_level_background() -> void:
	# Failsafe: Check if the string is empty so the game doesn't crash 
	# if you forgot to type a name in the Inspector for a specific level.
	if level_data.bg_animation_name == &"":
		return 
		
	# Tell the AnimationPlayer to play the string name we saved in the resource
	bg_animation_player.play(level_data.bg_animation_name)

func _populate_tilemap() -> void:
	var n: int = level_data.grid_size
	var total: int = n * n
	_validate_level_data(total)

	var tile_size = tile_map_layer.tile_set.tile_size.x
	var total_map_pixel_width = float(n * tile_size)

	# 1. Place the tiles as normal
	for i in total:
		var x = i % n
		var y = i / n
		var cell_coord := Vector2i(x, y)
		
		var source_id = level_data.tile_source_ids[i] if i < level_data.tile_source_ids.size() else 0
		tile_map_layer.set_cell(cell_coord, source_id, Vector2i.ZERO, 0)

	# 2. Reset TileMapLayer position just in case
	tile_map_layer.position = Vector2.ZERO

	# 3. Get the Camera2D node (assuming it's named "Camera2D" and is a sibling)
	#var camera: Camera2D = get_node("../Camera2D") # Adjust path if your script is on the TileMapLayer itself

	# 4. Center the Camera exactly in the middle of the generated map
	var map_center = total_map_pixel_width / 2.0
	camera.position = Vector2(map_center, map_center)

	# 5. Calculate the perfect zoom factor
	var vp_size = tile_map_layer.get_viewport().size
	var padding = 64.0 # Extra space so tiles don't touch the absolute edge of the UI frame
	var padded_map_size = total_map_pixel_width + padding
	
	# Divide the viewport size by the map size. 
	# min() ensures we scale based on the tightest dimension (x or y)
	var zoom_factor = min(vp_size.x, vp_size.y) / padded_map_size
	
	camera.zoom = Vector2(zoom_factor, zoom_factor)

func _input(event: InputEvent) -> void:
	if solved: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse_pos = tile_map_layer.get_local_mouse_position()
		var clicked_cell = tile_map_layer.local_to_map(local_mouse_pos)
		
		var n = level_data.grid_size
		if clicked_cell.x >= 0 and clicked_cell.x < n and clicked_cell.y >= 0 and clicked_cell.y < n:
			
			# Map 2D cell coordinate to 1D index
			var index = (clicked_cell.y * n) + clicked_cell.x
			
			# Check if the array has this data and if it's marked as fixed
			if index < level_data.locked_tiles.size() and level_data.locked_tiles[index]:
				print("This tile is locked!")
				return # Early exit! Ignore the click entirely.
				
			_rotate_tile_at(clicked_cell)

func _rotate_tile_at(cell: Vector2i) -> void:
	var source_id = tile_map_layer.get_cell_source_id(cell)
	var atlas_coords = tile_map_layer.get_cell_atlas_coords(cell)
	var current_alt = tile_map_layer.get_cell_alternative_tile(cell)
	
	# Decode Godot's bitwise transform alternatives into a 0-3 index
	var current_rot = 0
	if current_alt == (TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H): current_rot = 1
	if current_alt == (TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V): current_rot = 2
	if current_alt == (TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V): current_rot = 3
	
	# Clockwise rotation step
	var next_rot = (current_rot + 1) % 4
	
	# Encode back to Godot flags
	var next_alt = 0
	match next_rot:
		1: next_alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		2: next_alt = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		3: next_alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
		
	tile_map_layer.set_cell(cell, source_id, atlas_coords, next_alt)
	
	if _check_solved():
		solved = true
		_play_solved_sequence()

func _check_solved() -> bool:
	var n = level_data.grid_size
	for i in (n * n):
		var x = i % n
		var y = i / n
		var cell = Vector2i(x, y)
		
		var alt_id = tile_map_layer.get_cell_alternative_tile(cell)
		
		var current_rotation = 0
		if alt_id == (TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H): current_rotation = 1
		if alt_id == (TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V): current_rotation = 2
		if alt_id == (TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V): current_rotation = 3
		
		if current_rotation != level_data.target_rotations[i]:
			return false
	return true


## Catches level-authoring mistakes early and loudly, instead of
## silently defaulting to 0 or letting the puzzle spawn already solved.
func _validate_level_data(expected_count: int) -> void:
	# 1. Verify rotation solutions array
	if level_data.target_rotations.size() != expected_count:
		push_error("LevelData level_id=%d has %d target_rotations but grid_size=%d needs %d." % [
			level_data.level_id, level_data.target_rotations.size(), level_data.grid_size, expected_count
		])
		return

	# 2. Verify individual texture asset IDs array
	if level_data.tile_source_ids.size() != expected_count:
		push_error("LevelData level_id=%d has %d tile_source_ids but grid_size=%d needs %d." % [
			level_data.level_id, level_data.tile_source_ids.size(), level_data.grid_size, expected_count
		])
		return

	# 3. Handle locked tile allocations gracefully
	if level_data.locked_tiles.size() != expected_count:
		push_warning("LevelData level_id=%d: locked_tiles size mismatch or missing. Defaulting all to interactive." % level_data.level_id)
		# Safe programmatic fallback generation to prevent runtime crashes
		level_data.locked_tiles.resize(expected_count)
		level_data.locked_tiles.fill(false)

func _play_solved_sequence() -> void:
	# 1. Disable further input so the player can't mess up the board 
	# while the animation is playing.
	solved = true 
	
	art_display.texture = level_data.reveal_art
	
	# Wait a frame so the TextureRect has its final laid-out size before
	# using it to compute a center pivot for the scale-in animation.
	await get_tree().process_frame
	art_display.pivot_offset = art_display.size / 2.0
	art_display.scale = Vector2(0.85, 0.85)

	var tween := create_tween()
	tween.tween_property(art_display, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(art_display, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.4)
	
	# 2. Hand control to the global manager to load the next level
	tween.tween_callback(GameManager.level_complete)

func _on_back_button_pressed() -> void:
	GameManager.go_to_title()
