extends Resource
class_name LevelData

## Defines everything that differs between levels, so adding a new level is
## just a new .tres resource.

## Shown in the level label (e.g. "Level 1").
@export var level_id: int = 1

## The grid is always square: grid_size x grid_size cells.
@export var grid_size: int = 5

## The fixed solution. target_rotations[i] is the orientation (0-3 quarter
## turns clockwise) cell i must be rotated to for the puzzle to count it as
## solved. This is hand-authored per level, NOT generated at runtime - every
## square always starts at orientation 0, so this array IS the puzzle.
## Must contain exactly grid_size * grid_size entries, in row-major order
## (left-to-right, then top-to-bottom), matching GridContainer's fill order.
@export var target_rotations: Array[int] = []

## Texture applied to every grid square/button. A single shared texture is
## simplest, could give each LevelData its own for a different "look" per level.
@export var piece_texture: Texture2D

## The custom artwork revealed on the right-hand panel once the puzzle
## is solved.
@export var reveal_art: Texture2D
