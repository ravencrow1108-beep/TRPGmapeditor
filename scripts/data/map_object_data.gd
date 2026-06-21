##
## MapObjectData — An object on the map (token, prop, furniture, etc.).
##
class_name MapObjectData
extends Resource


# ---------- Collision shape enum ----------
enum CollisionShape {
	RECTANGLE,
	CIRCLE,
	POLYGON,
	GRID_FILL
}


@export var object_id: String = ""
@export var object_type: String = ""
@export var display_name: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var grid_position: Vector2i = Vector2i.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var sprite_path: String = ""
@export var z_index: int = 0
@export var collision_shape: int = CollisionShape.RECTANGLE
@export var custom_properties: Dictionary = {}
