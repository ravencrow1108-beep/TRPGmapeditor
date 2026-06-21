##
## FogData — Fog of war configuration and cell state grid per floor.
##
class_name FogData
extends Resource


# ---------- Fog type enum ----------
enum FogType {
	NONE,          ## Fog disabled
	GLOBAL,        ## Manual GM-controlled fog
	DYNAMIC,       ## Automatic fog updated by vision tokens
	REVEALED       ## Dynamic fog with persistent reveal (EXPLORED state)
}


# ---------- Fog cell state enum ----------
enum FogCellState {
	UNKNOWN,       ## Completely hidden → opaque black
	EXPLORED,      ## Previously seen → dim terrain visible, objects hidden
	VISIBLE        ## Currently visible → fully rendered
}


@export var enabled: bool = true
@export var fog_type: int = FogType.NONE
@export var fog_color: Color = Color.BLACK
@export var unexplored_color: Color = Color.BLACK
@export var explored_color: Color = Color(0.1, 0.1, 0.15, 0.6)
@export var fog_transition_speed: float = 0.5


## Fog cell grid: Dictionary of Vector2i → int (FogCellState).
@export var fog_grid: Dictionary = {}


## Per-token explored cells: Dictionary of token_id → Array[Vector2i].
@export var token_revealed: Dictionary = {}
