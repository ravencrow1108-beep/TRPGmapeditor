##
## PortalData — A portal connecting two positions (same map cross-floor or cross-map).
##
class_name PortalData
extends Resource


# ---------- Trigger type enum ----------
enum TriggerType {
	WALK_ON,      ## Activated when a token walks onto the portal area
	INTERACT,     ## Requires explicit interaction to activate
	AUTOMATIC     ## Activates immediately when a token enters range
}


@export var portal_id: String = ""
@export var portal_name: String = ""
@export var source_floor: int = 0
@export var source_position: Vector2i = Vector2i.ZERO
@export var source_size: Vector2i = Vector2i(1, 1)
@export var target_floor: int = 0
@export var target_position: Vector2i = Vector2i.ZERO
@export var target_map: String = ""   ## Empty = same map; path = cross-map
@export var is_bidirectional: bool = true
@export var is_active: bool = true
@export var visual_color: Color = Color(0.5, 0.3, 1.0, 0.7)
@export var label_visible: bool = true
@export var label_text: String = ""
@export var trigger_type: int = TriggerType.WALK_ON
