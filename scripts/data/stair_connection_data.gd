##
## StairConnectionData — A connection between two cells on different floors.
## Used for stairs, ladders, ramps, and elevator shafts.
##
class_name StairConnectionData
extends Resource


enum StairType {
	STAIRS,
	LADDER_UP,
	LADDER_DOWN,
	SHAFT,
	RAMP
}


@export var connection_id: String = ""
@export var stair_name: String = ""
@export var from_floor: int = 0
@export var from_position: Vector2i = Vector2i.ZERO
@export var to_floor: int = 0
@export var to_position: Vector2i = Vector2i.ZERO
@export var stair_type: int = StairType.STAIRS
@export var is_bidirectional: bool = true
