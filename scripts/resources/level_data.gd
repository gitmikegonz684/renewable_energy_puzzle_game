extends Resource
class_name LevelData

@export var level_id: int = 1
@export var grid_size: int = 5
@export var target_rotations: Array[int] = []

## Tracks the Source ID assigned to each individual image tile
@export var tile_source_ids: Array[int] = []
@export var reveal_art: Texture2D

## Tracks whether a tile is frozen/locked in place.
## true = fixed in position (clicking does nothing)
## false = normal rotatable puzzle piece
@export var locked_tiles: Array[bool] = []

## Unique background animation for each level
@export var bg_animation_name: StringName

## Flag tiles required for puzzle solution
## Ignores tiles when calculating solve state
@export var required_tiles: Array[bool] = []
