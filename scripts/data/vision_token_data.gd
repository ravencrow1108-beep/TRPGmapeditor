##
## VisionTokenData — A vision token on the map (player character, NPC, etc.).
## Defines vision parameters used by the shadowcasting engine.
##
class_name VisionTokenData
extends Resource


@export var token_id: String = ""
@export var token_name: String = ""
@export var floor_index: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var grid_position: Vector2i = Vector2i.ZERO
@export var vision_range: int = 8
@export var vision_arc: float = 360.0   ## Degrees — 360 = omnidirectional
@export var facing_angle: float = 0.0   ## Degrees — forward direction for cone vision
@export var darkvision_range: int = 0
@export var low_light_multiplier: float = 1.0
@export var visible_cells: Array[Vector2i] = []
@export var explored_cells: Array[Vector2i] = []
@export var vision_height: float = 1.5
@export var can_see_invisible: bool = false
@export var is_player_controlled: bool = false
@export var owner_player_id: String = ""
