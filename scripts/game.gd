extends Control

## Drives the entire "main game UI":
##   - left 2/3: an N x N grid of clickable/rotatable squares
##   - right 1/3: custom art (hidden until solved) + a "Main Menu" button
##
## The exact same scene/script is used for every level - grid_size, the
## piece texture, and the reveal art all come from GameManager.current_level_data.
## This is what makes level 2 a 10x10 with different art a content change
## (a new LevelData resource) rather than a code change.

## Target overall width/height (px) of the grid area, used to size cells
## so a 5x5 and a 10x10 grid both fit the left panel nicely.
const GRID_PIXEL_SIZE: float = 480.0

var level_data: LevelData
var squares: Array[GridSquare] = []
var solved: bool = false

var grid_container: GridContainer
var art_display: TextureRect
var level_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	level_data = GameManager.current_level_data
	if level_data == null:
		push_error("Game scene loaded without GameManager.current_level_data set.")
		return

	_build_ui()
	_populate_grid()


func _build_ui() -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# --- Left 2/3: the puzzle grid -----------------------------------
	var grid_area := CenterContainer.new()
	grid_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_area.size_flags_stretch_ratio = 2.0
	hbox.add_child(grid_area)

	grid_container = GridContainer.new()
	grid_container.columns = level_data.grid_size
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	grid_area.add_child(grid_container)

	# --- Right 1/3: custom art + navigation ---------------------------
	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	right_panel.add_theme_constant_override("separation", 12)
	hbox.add_child(right_panel)

	level_label = Label.new()
	level_label.text = "Level %d" % level_data.level_id
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_panel.add_child(level_label)

	art_display = TextureRect.new()
	art_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_display.modulate = Color(1, 1, 1, 0)  # hidden until the puzzle is solved
	right_panel.add_child(art_display)

	var back_button := Button.new()
	back_button.text = "Main Menu"
	back_button.custom_minimum_size = Vector2(0, 44)
	back_button.pressed.connect(func(): GameManager.go_to_title())
	right_panel.add_child(back_button)


func _populate_grid() -> void:
	var n: int = level_data.grid_size
	var total: int = n * n
	var cell_size := Vector2(GRID_PIXEL_SIZE / n, GRID_PIXEL_SIZE / n)

	_validate_level_data(total)

	for i in total:
		var target_steps: int = level_data.target_rotations[i] if i < level_data.target_rotations.size() else 0

		var sq := GridSquare.new()
		# Every square always starts at orientation 0 - target_rotations is
		# the entire puzzle. No randomness here: the same level always
		# presents the same starting grid and has the same single solution.
		sq.setup(level_data.piece_texture, 0, target_steps, cell_size)
		sq.rotated.connect(_on_square_rotated)

		grid_container.add_child(sq)
		squares.append(sq)


## Catches level-authoring mistakes early and loudly, instead of silently
## defaulting to 0 or letting the puzzle spawn already solved.
func _validate_level_data(expected_count: int) -> void:
	var rotations: Array[int] = level_data.target_rotations

	if rotations.size() != expected_count:
		push_error("LevelData level_id=%d has %d target_rotations but grid_size=%d needs %d." % [
			level_data.level_id, rotations.size(), level_data.grid_size, expected_count
		])
		return

	var all_zero := true
	for r in rotations:
		if r != 0:
			all_zero = false
			break
	if all_zero:
		push_warning("LevelData level_id=%d: every target_rotation is 0. Since every square also starts at 0, this puzzle would be solved instantly." % level_data.level_id)


func _on_square_rotated(_square: GridSquare) -> void:
	if solved:
		return
	if _check_solved():
		solved = true
		_play_solved_sequence()


func _check_solved() -> bool:
	for s in squares:
		if not s.is_correct():
			return false
	return true


func _play_solved_sequence() -> void:
	for s in squares:
		s.disabled = true

	art_display.texture = level_data.reveal_art

	# Wait a frame so the TextureRect has its final laid-out size before we
	# use it to compute a center pivot for the scale-in animation.
	await get_tree().process_frame
	art_display.pivot_offset = art_display.size / 2.0
	art_display.scale = Vector2(0.85, 0.85)

	var tween := create_tween()
	tween.tween_property(art_display, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(art_display, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.4)
	tween.tween_callback(GameManager.level_complete)
