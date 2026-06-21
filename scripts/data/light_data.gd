##
## LightData — A light source on the map (point, cone, directional, or ambient).
##
class_name LightData
extends Resource


# ---------- Light type enum ----------
enum LightType {
	POINT,
	CONE,
	DIRECTIONAL,
	AMBIENT
}


@export var light_id: String = ""
@export var light_name: String = ""
@export var floor_index: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var grid_position: Vector2i = Vector2i.ZERO
@export var light_type: int = LightType.POINT
@export var intensity: float = 1.0
@export var color: Color = Color(1.0, 0.95, 0.8, 1.0)
@export var radius: float = 5.0
@export var falloff: float = 0.5
@export var inner_angle: float = 30.0   ## Degrees — full intensity within this angle
@export var outer_angle: float = 60.0   ## Degrees — zero intensity beyond this angle
@export var rotation: float = 0.0
@export var is_static: bool = true
@export var is_dynamic: bool = false
@export var flicker_enabled: bool = false
@export var flicker_speed: float = 3.0
@export var flicker_amount: float = 0.15
