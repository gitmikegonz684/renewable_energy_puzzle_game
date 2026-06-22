extends TextureButton
class_name GridSquare

## One cell of the puzzle grid. Reused for every level regardless of grid
## size - the Game scene just creates grid_size * grid_size of these.

signal rotated(square: GridSquare)

## Keeps climbing by 90 every click (never wraps) so the animated rotation
## always visually spins clockwise.
var total_rotation_degrees: float = 0.0

## Current orientation, normalized to 0-3 quarter-turns. This is what
## actually gets compared against target_steps.
var rotation_steps: int = 0

## The orientation this square must be in for the puzzle to count it solved.
var target_steps: int = 0


func setup(p_texture: Texture2D, p_initial_steps: int, p_target_steps: int, p_size: Vector2) -> void:
	texture_normal = p_texture
	stretch_mode = TextureButton.STRETCH_SCALE
	custom_minimum_size = p_size
	size = p_size
	pivot_offset = p_size / 2.0
	ignore_texture_size = true
	rotation_steps = p_initial_steps
	target_steps = p_target_steps
	total_rotation_degrees = rotation_steps * 90.0
	rotation_degrees = total_rotation_degrees

	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	total_rotation_degrees += 90.0
	rotation_steps = int(total_rotation_degrees / 90.0) % 4

	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees", total_rotation_degrees, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	rotated.emit(self)


func is_correct() -> bool:
	return rotation_steps == target_steps
