##
## WallSegmentData — A single wall segment between two points.
## Walls have a type, dimensions, and bit-flag blocking properties.
##
class_name WallSegmentData
extends Resource


# ---------- Wall type enum ----------
enum WallType {
	SOLID,
	WINDOW,
	BARS,
	ILLUSION,
	HALF_HEIGHT,
	TRANSPARENT
}


# ---------- Block flags (bitwise combinable) ----------
const BLOCK_VISION: int     = 1 << 0   # 1
const BLOCK_LIGHT: int      = 1 << 1   # 2
const BLOCK_PROJECTILE: int = 1 << 2   # 4
const BLOCK_MOVEMENT: int   = 1 << 3   # 8
const BLOCK_FLYING: int     = 1 << 4   # 16
const BLOCK_BURROWING: int  = 1 << 5   # 32


@export var segment_id: String = ""
@export var start_point: Vector2 = Vector2.ZERO
@export var end_point: Vector2 = Vector2.ZERO
@export var wall_type: int = WallType.SOLID
@export var height: float = 2.0
@export var thickness: float = 0.3
@export var block_flags: int = BLOCK_VISION | BLOCK_LIGHT | BLOCK_PROJECTILE | BLOCK_MOVEMENT


## Helper: check if a specific block flag is set.
func has_flag(flag: int) -> bool:
	return (block_flags & flag) != 0


## Helper: set a specific block flag.
func set_flag(flag: int, enabled: bool) -> void:
	if enabled:
		block_flags |= flag
	else:
		block_flags &= ~flag
